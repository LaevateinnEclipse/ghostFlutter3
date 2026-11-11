import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/errors.dart';
import '../core/validators.dart';
import '../models/track.dart';
import '../repositories/track_repository.dart';
import '../state/catalog_notifier.dart';
import '../widgets/common.dart';
import '../widgets/dirty_guard.dart';
import '../widgets/entity_form.dart';

class TrackFormScreen extends StatefulWidget {
  final int? id;
  const TrackFormScreen({super.key, this.id});
  bool get isEditing => id != null;
  @override
  State<TrackFormScreen> createState() => _TrackFormScreenState();
}

class _TrackFormScreenState extends State<TrackFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _entityFormKey = GlobalKey<EntityFormState>();
  Track? _track;
  final Map<String, String?> _serverErrors = {};
  bool _loading = true;
  bool _dirty = false;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final catalog = context.read<CatalogNotifier>();
    final tracks = context.read<TrackRepository>();
    if (!catalog.loaded) await catalog.load();
    if (!mounted) return;
    Track? track;
    if (widget.id != null) {
      track = await tracks.findById(widget.id!);
    }
    if (!mounted) return;
    setState(() {
      _track = track;
      _loading = false;
    });
  }

  List<FieldSpec> _fields(CatalogNotifier catalog) {
    final track = _track;
    return [
      FieldSpec(
        name: 'title',
        label: 'Название',
        initialValue: track?.title,
        validators: [V.required(), V.length(min: 1, max: 120)],
      ),
      FieldSpec(
        name: 'albumId',
        label: 'Альбом',
        type: FieldType.dropdown,
        initialValue: track?.albumId,
        hint: 'Связь «многие к одному»',
        serverError: _serverErrors['albumId'],
        options: [
          for (final album in catalog.albums)
            DropdownEntry(album.id, '${album.title} (${album.year})'),
        ],
        validators: [V.notNull('Выберите альбом')],
      ),
      FieldSpec(
        name: 'trackNumber',
        label: 'Номер в альбоме',
        type: FieldType.number,
        initialValue: track?.trackNumber ?? 1,
        validators: [V.integer(min: 1, max: 40, label: 'Номер')],
        serverError: _serverErrors['trackNumber'],
        width: 200,
      ),
      FieldSpec(
        name: 'durationSeconds',
        label: 'Длительность, сек',
        type: FieldType.number,
        initialValue: track?.durationSeconds ?? 180,
        validators: [V.integer(min: 10, max: 1200, label: 'Длительность')],
        width: 220,
      ),
      FieldSpec(
        name: 'genre',
        label: 'Жанр',
        type: FieldType.dropdownText,
        initialValue: track?.genre ??
            (catalog.genres.isEmpty ? 'Heavy metal' : catalog.genres.first),
        textOptions: [
          for (final genre in catalog.genres) TextDropdownEntry(genre, genre),
        ],
        validators: [V.required(), V.length(min: 2, max: 40)],
        width: 280,
      ),
    ];
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final form = _entityFormKey.currentState;
    if (form == null) return;
    final tracks = context.read<TrackRepository>();
    final catalog = context.read<CatalogNotifier>();
    try {
      await tracks.save(Track(
            id: _track?.id ?? 0,
            title: form.string('title'),
            trackNumber: form.number('trackNumber'),
            durationSeconds: form.number('durationSeconds'),
            genre: form.string('genre'),
            albumId: form.number('albumId'),
            deletedAt: _track?.deletedAt,
          ));
      _dirty = false;
      await catalog.load();
      if (!mounted) return;
      context.go('/tracks');
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
      if (mounted) toast(context, 'Не удалось сохранить трек: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogNotifier>();
    return DirtyGuard(
      isDirty: () => _dirty,
      fallbackLocation: '/tracks',
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/tracks')),
          title: Text(widget.isEditing ? 'Редактирование трека' : 'Новый трек'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : widget.id != null && _track == null
                ? const Center(child: Text('Запись не найдена'))
                : EntityForm(
                    key: _entityFormKey,
                    fields: _fields(catalog),
                    formKey: _formKey,
                    saveLabel: widget.isEditing ? 'Сохранить изменения' : 'Создать трек',
                    onSubmit: _save,
                    onCancel: () => context.go('/tracks'),
                    onChanged: () => setState(() => _dirty = true),
                    rebuildToken: _revision,
                  ),
      ),
    );
  }
}
