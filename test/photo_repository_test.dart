// import 'package:flutter_test/flutter_test.dart';
// import 'package:photo_studio_portal/models/hall_query.dart';
// import 'package:photo_studio_portal/models/photographer_query.dart';
// import 'package:photo_studio_portal/repositories/in_memory_hall_repository.dart';
// import 'package:photo_studio_portal/repositories/in_memory_photographer_repository.dart';

// void main() {
//   test('каталог возвращает страницу из 10 записей', () async {
//     final result = await InMemoryHallRepository().find(const HallQuery());
//     expect(result.items, hasLength(10));
//     expect(result.total, greaterThanOrEqualTo(20));
//   });

//   test('фильтр стиля возвращает только подходящие залы', () async {
//     final result =
//         await InMemoryHallRepository().find(const HallQuery(style: 'Лофт'));
//     expect(result.items, isNotEmpty);
//     expect(result.items.every((hall) => hall.style == 'Лофт'), isTrue);
//   });

//   test('логическое удаление скрывает зал из обычной выборки', () async {
//     final repo = InMemoryHallRepository();
//     final id = (await repo.find(const HallQuery())).items.first.id;
//     await repo.softDelete(id);
//     expect(
//         (await repo.find(const HallQuery(size: 50)))
//             .items
//             .any((hall) => hall.id == id),
//         isFalse);
//   });

//   test('поиск фотографов выполняется по специализации', () async {
//     final result = await InMemoryPhotographerRepository()
//         .find(const PhotographerQuery(search: 'fashion'));
//     expect(result.items, isNotEmpty);
//     expect(
//         result.items.every((person) =>
//             person.specialization.toLowerCase().contains('fashion')),
//         isTrue);
//   });
// }
