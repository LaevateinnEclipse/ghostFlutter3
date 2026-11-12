import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/form_outcome.dart';
import '../core/validators.dart';
import '../data/seed_data.dart';
import '../models/album.dart';
import '../repositories/album_repository.dart';
import '../state/catalog_notifier.dart';
import '../widgets/dirty_guard.dart';
import '../widgets/entity_form.dart';

class AlbumFormScreen extends StatefulWidget {
  final int? id;
  const AlbumFormScreen({super.key, this.id});
  bool get isEditing => id != null;
  @override
  State<AlbumFormScreen> createState() => _AlbumFormScreenState();
}

class _AlbumFormScreenState extends State<AlbumFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _entityFormKey = GlobalKey<EntityFormState>();
  Album? _album;
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
    final albums = context.read<AlbumRepository>();
    if (!catalog.loaded) await catalog.load();
    if (!mounted) return;
    Album? album;
    if (widget.id != null) {
      album = await albums.findById(widget.id!);
    }
    if (!mounted) return;
    setState(() {
      _album = album;
      _loading = false;
    });
  }

  List<FieldSpec> _fields() {
    final album = _album;
    return [
      FieldSpec(
        name: 'title',
        label: 'Название',
        initialValue: album?.title,
        validators: [V.required(), V.length(min: 2, max: 80)],
      ),
      FieldSpec(
        name: 'catalogCode',
        label: 'Каталожный номер',
        initialValue: album?.catalogCode,
        hint: 'Уникальный код, например GH-ALB-013',
        validators: [
          V.required(),
          V.length(min: 4, max: 20),
          (value) => RegExp(r'^[A-Za-z0-9-]+$').hasMatch(value?.trim() ?? '')
              ? null
              : 'Допустимы латинские буквы, цифры и дефис',
        ],
        serverError: _serverErrors['catalogCode'],
        width: 280,
      ),
      FieldSpec(
        name: 'albumType',
        label: 'Тип',
        type: FieldType.dropdownText,
        initialValue: album?.albumType ?? 'studio',
        textOptions: [
          for (final type in Album.types)
            TextDropdownEntry(type, albumTypeLabel(type)),
        ],
        validators: [V.notNull('Выберите тип альбома')],
        width: 240,
      ),
      FieldSpec(
        name: 'year',
        label: 'Год',
        type: FieldType.number,
        initialValue: album?.year ?? DateTime.now().year,
        validators: [V.integer(min: 1960, max: 2100, label: 'Год')],
        width: 160,
      ),
      FieldSpec(
        name: 'label',
        label: 'Лейбл',
        initialValue: album?.label,
        validators: [V.required(), V.length(min: 2, max: 80)],
        width: 280,
      ),
      FieldSpec(
        name: 'coverUrl',
        label: 'Обложка',
        initialValue: album?.coverUrl ?? '',
        hint: 'Путь или ссылка, можно оставить пустым',
        validators: [V.length(max: 200)],
      ),
    ];
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final form = _entityFormKey.currentState;
    if (form == null) return;
    final albums = context.read<AlbumRepository>();
    final catalog = context.read<CatalogNotifier>();
    setState(() => _saving = true);
    try {
      await albums.save(Album(
            id: _album?.id ?? 0,
            title: form.string('title'),
            catalogCode: form.string('catalogCode'),
            albumType: form.string('albumType'),
            year: form.number('year'),
            label: form.string('label'),
            coverUrl: form.string('coverUrl'),
            memberIds: _album?.memberIds ?? const [],
            trackIds: _album?.trackIds ?? const [],
            concertIds: _album?.concertIds ?? const [],
            deletedAt: _album?.deletedAt,
          ));
      _dirty = false;
      await catalog.load(force: true);
      if (!mounted) return;
      context.go('/albums');
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

  @override
  Widget build(BuildContext context) {
    return DirtyGuard(
      isDirty: () => _dirty,
      fallbackLocation: '/albums',
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/albums')),
          title: Text(widget.isEditing ? 'Редактирование альбома' : 'Новый альбом'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : widget.id != null && _album == null
                ? const Center(child: Text('Запись не найдена'))
                : EntityForm(
                    key: _entityFormKey,
                    fields: _fields(),
                    formKey: _formKey,
                    saveLabel: widget.isEditing ? 'Сохранить изменения' : 'Создать альбом',
                    onSubmit: _save,
                    onCancel: () => context.go('/albums'),
                    saving: _saving,
                    onChanged: () => setState(() => _dirty = true),
                    rebuildToken: _revision,
                  ),
      ),
    );
  }
}
