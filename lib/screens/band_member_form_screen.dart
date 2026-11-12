import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/form_outcome.dart';
import '../core/validators.dart';
import '../models/band_member.dart';
import '../repositories/band_member_repository.dart';
import '../state/catalog_notifier.dart';
import '../widgets/dirty_guard.dart';
import '../widgets/entity_form.dart';

class BandMemberFormScreen extends StatefulWidget {
  final int? id;
  const BandMemberFormScreen({super.key, this.id});
  bool get isEditing => id != null;
  @override
  State<BandMemberFormScreen> createState() => _BandMemberFormScreenState();
}

class _BandMemberFormScreenState extends State<BandMemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _entityFormKey = GlobalKey<EntityFormState>();
  BandMember? _member;
  final Map<String, String?> _serverErrors = {};
  bool _loading = true;
  bool _dirty = false;
  bool _saving = false;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final catalog = context.read<CatalogNotifier>();
    final members = context.read<BandMemberRepository>();
    if (!catalog.loaded) await catalog.load();
    if (!mounted) return;
    BandMember? member;
    if (widget.id != null) {
      member = await members.findById(widget.id!);
    }
    if (!mounted) return;
    setState(() {
      _member = member;
      _loading = false;
    });
  }

  List<FieldSpec> _fields(CatalogNotifier catalog) {
    final member = _member;
    final today = DateTime.now();
    return [
      FieldSpec(
        name: 'firstName',
        label: 'Имя',
        initialValue: member?.firstName,
        validators: [V.required(), V.length(min: 2, max: 40)],
        width: 260,
      ),
      FieldSpec(
        name: 'lastName',
        label: 'Фамилия',
        initialValue: member?.lastName,
        validators: [V.required(), V.length(min: 2, max: 40)],
        width: 260,
      ),
      FieldSpec(
        name: 'role',
        label: 'Инструмент / роль',
        type: FieldType.dropdownText,
        initialValue: member?.role ?? 'Гитара',
        textOptions: [
          for (final role in catalog.roles) TextDropdownEntry(role, role),
        ],
        validators: [V.required(), V.length(min: 2, max: 40)],
        width: 260,
      ),
      FieldSpec(
        name: 'email',
        label: 'Почта',
        type: FieldType.email,
        initialValue: member?.email,
        hint: 'Уникальный адрес',
        validators: [V.required(), V.length(max: 254), V.email()],
        serverError: _serverErrors['email'],
        width: 320,
      ),
      FieldSpec(
        name: 'joinedYear',
        label: 'Год вступления',
        type: FieldType.number,
        initialValue: member?.joinedYear == 0
            ? today.year
            : (member?.joinedYear ?? today.year),
        validators: [V.integer(min: 1960, max: today.year, label: 'Год')],
        width: 200,
      ),
      FieldSpec(
        name: 'yearsInBand',
        label: 'Лет в группе',
        type: FieldType.number,
        initialValue: member?.yearsInBand ?? 1,
        validators: [V.integer(min: 0, max: 60, label: 'Стаж')],
        width: 180,
      ),
      FieldSpec(
        name: 'fee',
        label: 'Гонорар, ₽',
        type: FieldType.number,
        initialValue: member?.fee ?? 10000,
        validators: [V.positive(label: 'Гонорар')],
        width: 200,
      ),
      FieldSpec(
        name: 'photoUrl',
        label: 'Фото',
        initialValue: member?.photoUrl ?? '',
        hint: 'Путь или ссылка, можно оставить пустым',
        validators: [V.length(max: 200)],
      ),
      FieldSpec(
        name: 'bio',
        label: 'Биография',
        type: FieldType.multiline,
        initialValue: member?.bio ?? '',
        validators: [V.length(max: 500)],
      ),
      FieldSpec(
        name: 'albumIds',
        label: 'Альбомы',
        type: FieldType.multiselect,
        initialValue: member?.albumIds ?? const <int>[],
        hint: 'Связь «многие ко многим»',
        isWideList: true,
        serverError: _serverErrors['albumIds'],
        options: [
          for (final album in catalog.albums)
            DropdownEntry(album.id, album.title),
        ],
        validators: [
          (value) => value == null || value.trim().isEmpty
              ? 'Выберите хотя бы один альбом'
              : null,
        ],
      ),
      FieldSpec(
        name: 'stageName',
        label: 'Сценическое имя',
        initialValue: member?.stageName,
        groupTitle: 'Сценический образ',
        validators: [V.required(), V.length(min: 2, max: 40)],
        width: 280,
      ),
      FieldSpec(
        name: 'maskCode',
        label: 'Код маски',
        initialValue: member?.maskCode,
        hint: 'Уникальный код, например GH-AIR',
        groupTitle: 'Сценический образ',
        validators: [
          V.required(),
          V.length(min: 3, max: 20),
          (value) => RegExp(r'^[A-Za-z0-9-]+$').hasMatch(value?.trim() ?? '')
              ? null
              : 'Допустимы латинские буквы, цифры и дефис',
        ],
        serverError: _serverErrors['maskCode'],
        width: 240,
      ),
      FieldSpec(
        name: 'appointedOn',
        label: 'Образ назначен (ГГГГ-ММ-ДД)',
        type: FieldType.date,
        initialValue: member == null || member.appointedOn.isEmpty
            ? _dateText(today)
            : member.appointedOn,
        groupTitle: 'Сценический образ',
        validators: [V.date(min: DateTime(1960), max: today)],
        width: 280,
      ),
    ];
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final form = _entityFormKey.currentState;
    if (form == null) return;
    final members = context.read<BandMemberRepository>();
    final catalog = context.read<CatalogNotifier>();
    setState(() => _saving = true);
    try {
      await members.save(BandMember(
            id: _member?.id ?? 0,
            firstName: form.string('firstName'),
            lastName: form.string('lastName'),
            role: form.string('role'),
            yearsInBand: form.number('yearsInBand'),
            fee: form.number('fee'),
            email: form.string('email'),
            bio: form.string('bio'),
            photoUrl: form.string('photoUrl'),
            joinedYear: form.number('joinedYear'),
            stageName: form.string('stageName'),
            maskCode: form.string('maskCode'),
            appointedOn: form.string('appointedOn'),
            albumIds: form.selection('albumIds'),
            concertIds: _member?.concertIds ?? const [],
            deletedAt: _member?.deletedAt,
          ));
      _dirty = false;
      await catalog.load(force: true);
      if (!mounted) return;
      context.go('/members');
    } catch (error) {
      if (!mounted) return;
      consumeFormError(
        context,
        error,
        reject: (field) => _entityFormKey.currentState?.rejectValue(field),
        showOnFields: (errors) {
          setState(() {
            _serverErrors
              ..clear()
              ..addAll(errors);
            _revision++;
          });
          _formKey.currentState?.validate();
        },
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _dateText(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogNotifier>();
    return DirtyGuard(
      isDirty: () => _dirty,
      fallbackLocation: '/members',
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/members')),
          title: Text(widget.isEditing
              ? 'Редактирование участника'
              : 'Новый участник'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : widget.id != null && _member == null
                ? const Center(child: Text('Запись не найдена'))
                : EntityForm(
                    key: _entityFormKey,
                    fields: _fields(catalog),
                    formKey: _formKey,
                    saveLabel: widget.isEditing
                        ? 'Сохранить изменения'
                        : 'Добавить участника',
                    onSubmit: _save,
                    onCancel: () => context.go('/members'),
                    saving: _saving,
                    onChanged: () => setState(() => _dirty = true),
                    rebuildToken: _revision,
                  ),
      ),
    );
  }
}
