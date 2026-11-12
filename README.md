Из этой папки в первом терминале:

```
node server/mock-server.js --port 8080 --origin http://localhost:5555
```

Во втором терминале:

```
flutter pub get
flutter run -d chrome --web-port=5555
```

Проверка сервера: http://localhost:8080/api/__health

Списки, карточки и формы ходят в REST API через Dio. Хранилище в памяти в приложении больше не используется. Поиск, фильтры, сортировка и страницы считаются на сервере.

Другой адрес сервера:

```
flutter run -d chrome --web-port=5555 --dart-define=API_BASE_URL=http://192.168.1.10:8080/api
```

Индикатор загрузки:

```
flutter run -d chrome --web-port=5555 --dart-define=API_DEMO_DELAY_MS=1500
```

Принудительная ошибка 500:

```
flutter run -d chrome --web-port=5555 --dart-define=API_DEMO_FAIL=500
```

Ошибка 422: сохраните альбом с каталожным номером `GH-ALB-001`. Ошибка 409: новый концерт на площадку, которая в этот день уже занята, либо удаление альбома, у которого есть треки.
