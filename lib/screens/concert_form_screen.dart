import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/errors.dart';
import '../core/validators.dart';
import '../data/seed_data.dart';
import '../models/band_member.dart';
import '../models/concert.dart';
import '../repositories/concert_repository.dart';
import '../state/catalog_notifier.dart';
import '../widgets/common.dart';
import '../widgets/dirty_guard.dart';
import '../widgets/entity_form.dart';

class ConcertFormScreen extends StatefulWidget {
  final int? id;
  const ConcertFormScreen({super.key, this.id});
  bool get isEditing => id != null;
  @override
  State<ConcertFormScreen> createState() => _ConcertFormScreenState();
}

class _ConcertFormScreenState extends State<ConcertFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _entityFormKey = GlobalKey<EntityFormState>();
  Concert? _concert;
  final Map<String, String?> _serverErrors = {};
  bool _loading = true;
  bool _dirty = false;
  int? _albumId;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final catalog = context.read<CatalogNotifier>();
    final concerts = context.read<ConcertRepository>();
    if (!catalog.loaded) await catalog.load();
    if (!mounted) return;
    Concert? concert;
    if (widget.id != null) {
      concert = await concerts.findById(widget.id!);
    }
    if (!mounted) return;
    setState(() {
      _concert = concert;
      _albumId = concert?.albumId;
      _loading = false;
    });
  }

  List<BandMember> _lineup(CatalogNotifier catalog) {
    final albumId = _albumId;
    if (albumId == null) return catalog.members;
    return catalog.members
        .where((member) =>
            member.albumIds.isEmpty || member.albumIds.contains(albumId))
        .toList();
  }

  void _onAlbumChanged(int? albumId) {
    final catalog = context.read<CatalogNotifier>();
    final available = catalog.members
        .where((member) =>
            albumId == null ||
            member.albumIds.isEmpty ||
            member.albumIds.contains(albumId))
        .map((member) => member.id)
        .toSet();
    final selected = _entityFormKey.currentState?.selection('memberIds') ??
        _concert?.memberIds ??
        const <int>[];
    final kept = selected.where(available.contains).toList();
    if (kept.length != selected.length) {
      _entityFormKey.currentState?.setValue('memberIds', kept);
    }
    setState(() {
      _albumId = albumId;
      _dirty = true;
      _revision++;
    });
  }

  List<FieldSpec> _fields(CatalogNotifier catalog) {
    final concert = _concert;
    return [
      FieldSpec(
        name: 'city',
        label: 'Город',
        initialValue: concert?.city,
        validators: [V.required(), V.length(min: 2, max: 60)],
        width: 240,
      ),
      FieldSpec(
        name: 'venue',
        label: 'Площадка',
        initialValue: concert?.venue,
        validators: [V.required(), V.length(min: 2, max: 80)],
        width: 320,
      ),
      FieldSpec(
        name: 'date',
        label: 'Дата (ГГГГ-ММ-ДД)',
        type: FieldType.date,
        initialValue: concert == null
            ? _dateText(DateTime.now().add(const Duration(days: 14)))
            : _dateText(concert.date),
        validators: [
          (value) => concert != null && value == _dateText(concert.date)
              ? V.date()(value)
              : V.date()(value),
        ],
        width: 240,
      ),
      FieldSpec(
        name: 'albumId',
        label: 'Альбом тура',
        type: FieldType.dropdown,
        initialValue: _albumId,
        hint: 'Список участников сузится до состава этого альбома',
        serverError: _serverErrors['albumId'],
        options: [
          for (final album in catalog.albums)
            DropdownEntry(album.id, album.title),
        ],
        validators: [V.notNull('Выберите альбом')],
        onChanged: (value) => _onAlbumChanged(value as int?),
      ),
      FieldSpec(
        name: 'memberIds',
        label: 'Состав на концерте',
        type: FieldType.multiselect,
        initialValue: concert?.memberIds ?? const <int>[],
        hint: 'Связь «многие ко многим»',
        isWideList: true,
        serverError: _serverErrors['memberIds'],
        options: [
          for (final member in _lineup(catalog))
            DropdownEntry(member.id, '${member.fullName} — ${member.role}'),
        ],
        validators: [
          (value) => value == null || value.trim().isEmpty
              ? 'Выберите хотя бы одного участника'
              : null,
        ],
      ),
      FieldSpec(
        name: 'ticketCode',
        label: 'Код билета',
        initialValue: concert?.ticketCode,
        hint: 'Уникальный код, например GH-STO-013',
        groupTitle: 'Билет',
        validators: [
          V.required(),
          V.length(min: 6, max: 20),
          (value) => RegExp(r'^[A-Za-z0-9-]+$').hasMatch(value?.trim() ?? '')
              ? null
              : 'Допустимы латинские буквы, цифры и дефис',
        ],
        serverError: _serverErrors['ticketCode'],
        width: 260,
      ),
      FieldSpec(
        name: 'ticketPrice',
        label: 'Цена, ₽',
        type: FieldType.number,
        initialValue: concert?.ticketPrice ?? 1000,
        groupTitle: 'Билет',
        validators: [V.integer(min: 0, max: 1000000, label: 'Цена')],
        width: 180,
      ),
      FieldSpec(
        name: 'contactEmail',
        label: 'Почта организатора',
        type: FieldType.email,
        initialValue: concert?.contactEmail,
        groupTitle: 'Билет',
        validators: [V.required(), V.length(max: 254), V.email()],
        width: 320,
      ),
      FieldSpec(
        name: 'status',
        label: 'Статус',
        type: FieldType.dropdownText,
        initialValue: concert?.status ?? 'plan',
        groupTitle: 'Билет',
        textOptions: [
          for (final status in Concert.statuses)
            TextDropdownEntry(status, concertStatusLabel(status)),
        ],
        validators: [V.notNull('Выберите статус')],
        width: 220,
      ),
    ];
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final form = _entityFormKey.currentState;
    if (form == null) return;
    final concerts = context.read<ConcertRepository>();
    final catalog = context.read<CatalogNotifier>();
    try {
      await concerts.save(Concert(
            id: _concert?.id ?? 0,
            city: form.string('city'),
            venue: form.string('venue'),
            date: DateTime.tryParse(form.string('date')) ?? DateTime.now(),
            ticketPrice: form.number('ticketPrice'),
            status: form.string('status'),
            albumId: form.number('albumId'),
            memberIds: form.selection('memberIds'),
            ticketCode: form.string('ticketCode'),
            contactEmail: form.string('contactEmail'),
            deletedAt: _concert?.deletedAt,
          ));
      _dirty = false;
      await catalog.load();
      if (!mounted) return;
      context.go('/concerts');
    } on FieldValidationException catch (error) {
      if (!mounted) return;
      _entityFormKey.currentState?.rejectValue(error.field);
      setState(() {
        _serverErrors
          ..clear()
          ..[error.field] = error.message;
        _revision++;
      });
      _formKey.currentState?.validate();
    } catch (error) {
      if (mounted) toast(context, 'Не удалось сохранить концерт: $error');
    }
  }

  String _dateText(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogNotifier>();
    return DirtyGuard(
      isDirty: () => _dirty,
      fallbackLocation: '/concerts',
      message: 'Есть несохранённые изменения в афише. Выйти без сохранения?',
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/concerts')),
          title: Text(
              widget.isEditing ? 'Редактирование концерта' : 'Новый концерт'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : widget.id != null && _concert == null
                ? const Center(child: Text('Запись не найдена'))
                : EntityForm(
                    key: _entityFormKey,
                    fields: _fields(catalog),
                    formKey: _formKey,
                    saveLabel: widget.isEditing
                        ? 'Сохранить изменения'
                        : 'Создать концерт',
                    onSubmit: _save,
                    onCancel: () => context.go('/concerts'),
                    onChanged: () => setState(() => _dirty = true),
                    rebuildToken: _revision,
                  ),
      ),
    );
  }
}
