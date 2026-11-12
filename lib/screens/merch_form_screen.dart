import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/form_outcome.dart';
import '../core/validators.dart';
import '../models/merch_item.dart';
import '../repositories/merch_repository.dart';
import '../state/catalog_notifier.dart';
import '../widgets/dirty_guard.dart';
import '../widgets/entity_form.dart';

class MerchFormScreen extends StatefulWidget {
  final int? id;
  const MerchFormScreen({super.key, this.id});
  bool get isEditing => id != null;
  @override
  State<MerchFormScreen> createState() => _MerchFormScreenState();
}

class _MerchFormScreenState extends State<MerchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _entityFormKey = GlobalKey<EntityFormState>();
  MerchItem? _item;
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
    final merch = context.read<MerchRepository>();
    if (!catalog.loaded) await catalog.load();
    if (!mounted) return;
    MerchItem? item;
    if (widget.id != null) {
      item = await merch.findById(widget.id!);
    }
    if (!mounted) return;
    setState(() {
      _item = item;
      _loading = false;
    });
  }

  List<FieldSpec> _fields(CatalogNotifier catalog) {
    final item = _item;
    return [
      FieldSpec(
        name: 'name',
        label: 'Название',
        initialValue: item?.name,
        validators: [V.required(), V.length(min: 2, max: 80)],
      ),
      FieldSpec(
        name: 'sku',
        label: 'Артикул',
        initialValue: item?.sku,
        hint: 'Уникальный артикул, например GH-013',
        validators: [
          V.required(),
          V.length(min: 3, max: 20),
          (value) => RegExp(r'^[A-Za-z0-9-]+$').hasMatch(value?.trim() ?? '')
              ? null
              : 'Допустимы латинские буквы, цифры и дефис',
        ],
        serverError: _serverErrors['sku'],
        width: 240,
      ),
      FieldSpec(
        name: 'category',
        label: 'Категория',
        type: FieldType.dropdownText,
        initialValue: item?.category ??
            (catalog.categories.isEmpty ? 'Одежда' : catalog.categories.first),
        textOptions: [
          for (final category in catalog.categories)
            TextDropdownEntry(category, category),
        ],
        validators: [V.required(), V.length(min: 2, max: 40)],
        width: 240,
      ),
      FieldSpec(
        name: 'albumId',
        label: 'Альбом',
        type: FieldType.dropdown,
        initialValue: item == null || item.albumId == 0 ? null : item.albumId,
        hint: 'Связь «многие к одному»: мерч относится к релизу',
        serverError: _serverErrors['albumId'],
        options: [
          for (final album in catalog.albums)
            DropdownEntry(album.id, album.title),
        ],
        validators: [V.notNull('Выберите альбом')],
      ),
      FieldSpec(
        name: 'stock',
        label: 'Остаток',
        type: FieldType.number,
        initialValue: item?.stock ?? 1,
        validators: [V.integer(min: 0, max: 100000, label: 'Остаток')],
        width: 160,
      ),
      FieldSpec(
        name: 'price',
        label: 'Цена, ₽',
        type: FieldType.number,
        initialValue: item?.price ?? 1000,
        validators: [V.positive(label: 'Цена')],
        width: 180,
      ),
    ];
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final form = _entityFormKey.currentState;
    if (form == null) return;
    final merch = context.read<MerchRepository>();
    final catalog = context.read<CatalogNotifier>();
    setState(() => _saving = true);
    try {
      await merch.save(MerchItem(
            id: _item?.id ?? 0,
            name: form.string('name'),
            sku: form.string('sku'),
            category: form.string('category'),
            stock: form.number('stock'),
            price: form.number('price'),
            sizeIds: _item?.sizeIds ?? const [],
            albumId: form.number('albumId'),
            deletedAt: _item?.deletedAt,
          ));
      _dirty = false;
      await catalog.load(force: true);
      if (!mounted) return;
      context.go('/merch');
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
    final catalog = context.watch<CatalogNotifier>();
    return DirtyGuard(
      isDirty: () => _dirty,
      fallbackLocation: '/merch',
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/merch')),
          title: Text(widget.isEditing ? 'Редактирование мерча' : 'Новый товар'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : widget.id != null && _item == null
                ? const Center(child: Text('Запись не найдена'))
                : EntityForm(
                    key: _entityFormKey,
                    fields: _fields(catalog),
                    formKey: _formKey,
                    saveLabel:
                        widget.isEditing ? 'Сохранить изменения' : 'Создать товар',
                    onSubmit: _save,
                    onCancel: () => context.go('/merch'),
                    saving: _saving,
                    onChanged: () => setState(() => _dirty = true),
                    rebuildToken: _revision,
                  ),
      ),
    );
  }
}
