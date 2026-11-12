const http = require('node:http');
const fs = require('node:fs');
const nodePath = require('node:path');
const seed = require('./seed-ghost');

const args = process.argv.slice(2);
function arg(name, fallback) {
  const index = args.indexOf(`--${name}`);
  if (index < 0 || index + 1 >= args.length) return fallback;
  return args[index + 1];
}

const PORT = Number(arg('port', 8080));
const ORIGIN = arg('origin', 'http://localhost:5555');
const COLLECTIONS = ['albums', 'members', 'tracks', 'merch', 'concerts'];
const ALBUM_TYPES = ['studio', 'live', 'EP', 'single'];
const CONCERT_STATUSES = ['plan', 'done', 'cancelled'];

let db;

function fresh() {
  db = {
    albums: seed.albums.map((row) => ({ ...row, albumIds: undefined })),
    members: seed.members.map((row) => ({ ...row, albumIds: [...row.albumIds] })),
    tracks: seed.tracks.map((row) => ({ ...row })),
    merch: seed.merch.map((row) => ({ ...row, sizeIds: [...row.sizeIds] })),
    concerts: seed.concerts.map((row) => ({ ...row, memberIds: [...row.memberIds] })),
  };
  for (const album of db.albums) delete album.albumIds;
}

function str(value) {
  return value == null ? '' : String(value).trim();
}

function num(value) {
  if (value == null || value === '') return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function ids(value) {
  if (!Array.isArray(value)) return [];
  return value.map(Number).filter((id) => Number.isInteger(id) && id > 0);
}

function dayOf(value) {
  const text = str(value);
  if (!text) return '';
  return text.slice(0, 10);
}

function active(row, hard = false) {
  return hard || !row.deletedAt;
}

function findActive(collection, id) {
  return db[collection].find((row) => row.id === Number(id) && !row.deletedAt);
}

function expandAlbum(row) {
  return {
    ...row,
    trackIds: db.tracks.filter((track) => track.albumId === row.id).map((track) => track.id),
    concertIds: db.concerts.filter((concert) => concert.albumId === row.id).map((concert) => concert.id),
    memberIds: db.members
      .filter((member) => (member.albumIds || []).includes(row.id))
      .map((member) => member.id),
  };
}

function expandMember(row) {
  return {
    ...row,
    concertIds: db.concerts
      .filter((concert) => (concert.memberIds || []).includes(row.id))
      .map((concert) => concert.id),
  };
}

const EXPANDERS = {
  albums: expandAlbum,
  members: expandMember,
  tracks: (row) => ({ ...row }),
  merch: (row) => ({ ...row, sizeIds: [...(row.sizeIds || [])] }),
  concerts: (row) => ({ ...row, memberIds: [...(row.memberIds || [])] }),
};

function searchable(collection, row) {
  const parts = {
    albums: [row.title, row.catalogCode, row.label],
    members: [row.firstName, row.lastName, row.stageName, row.email, row.maskCode, row.role],
    tracks: [row.title, row.genre],
    merch: [row.name, row.sku, row.category],
    concerts: [row.city, row.venue, row.ticketCode, row.contactEmail],
  }[collection];
  return parts.join(' ').toLowerCase();
}

function applyFilters(collection, rows, query) {
  let result = rows;
  const search = str(query.search).toLowerCase();
  if (search) result = result.filter((row) => searchable(collection, row).includes(search));

  if (collection === 'albums') {
    if (query.albumType) result = result.filter((row) => row.albumType === query.albumType);
    const from = num(query.yearFrom);
    const to = num(query.yearTo);
    if (from != null) result = result.filter((row) => row.year >= from);
    if (to != null) result = result.filter((row) => row.year <= to);
  }
  if (collection === 'members') {
    if (query.role) result = result.filter((row) => row.role === query.role);
    const from = num(query.yearsFrom);
    const to = num(query.yearsTo);
    if (from != null) result = result.filter((row) => row.yearsInBand >= from);
    if (to != null) result = result.filter((row) => row.yearsInBand <= to);
  }
  if (collection === 'tracks') {
    const albumId = num(query.albumId);
    if (albumId != null) result = result.filter((row) => row.albumId === albumId);
    if (query.genre) result = result.filter((row) => row.genre === query.genre);
  }
  if (collection === 'merch') {
    if (query.category) result = result.filter((row) => row.category === query.category);
    const stockFrom = num(query.stockFrom);
    const stockTo = num(query.stockTo);
    const priceFrom = num(query.priceFrom);
    const priceTo = num(query.priceTo);
    if (stockFrom != null) result = result.filter((row) => row.stock >= stockFrom);
    if (stockTo != null) result = result.filter((row) => row.stock <= stockTo);
    if (priceFrom != null) result = result.filter((row) => row.price >= priceFrom);
    if (priceTo != null) result = result.filter((row) => row.price <= priceTo);
    const albumId = num(query.albumId);
    if (albumId != null) result = result.filter((row) => row.albumId === albumId);
  }
  if (collection === 'concerts') {
    if (query.status) result = result.filter((row) => row.status === query.status);
    if (query.city) result = result.filter((row) => row.city === query.city);
    const albumId = num(query.albumId);
    const memberId = num(query.memberId);
    if (albumId != null) result = result.filter((row) => row.albumId === albumId);
    if (memberId != null) result = result.filter((row) => (row.memberIds || []).includes(memberId));
  }
  return result;
}

function applySort(rows, sort) {
  if (!sort) return rows;
  const [field, direction] = String(sort).split(',');
  const sign = (direction || 'asc').toLowerCase() === 'desc' ? -1 : 1;
  return [...rows].sort((left, right) => {
    const a = left[field];
    const b = right[field];
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    if (typeof a === 'number' && typeof b === 'number') return (a - b) * sign;
    return String(a).localeCompare(String(b), 'ru') * sign;
  });
}

function paginate(rows, query) {
  const page = Math.max(1, Number(query.page) || 1);
  const size = Math.min(100, Math.max(1, Number(query.size) || 10));
  const total = rows.length;
  return {
    items: rows.slice((page - 1) * size, page * size),
    page,
    size,
    total,
    totalPages: Math.max(1, Math.ceil(total / size)),
  };
}

function emailOk(value) {
  return /^[\w.+-]+@[\w-]+\.[\w.-]+$/.test(value);
}

function codeOk(value, min, max) {
  return new RegExp(`^[A-Za-z0-9-]{${min},${max}}$`).test(value);
}

function validate(collection, body, id = null) {
  const errors = {};
  const same = (row) => row.id !== id && !row.deletedAt;

  if (collection === 'albums') {
    const title = str(body.title);
    const code = str(body.catalogCode).toUpperCase();
    const label = str(body.label);
    if (title.length < 2 || title.length > 80) errors.title = 'Название: от 2 до 80 символов';
    if (!codeOk(code, 4, 20)) errors.catalogCode = 'Допустимы латинские буквы, цифры и дефис, от 4 до 20 символов';
    else if (db.albums.some((row) => same(row) && row.catalogCode.toUpperCase() === code)) {
      errors.catalogCode = 'Альбом с таким каталожным номером уже есть';
    }
    if (!ALBUM_TYPES.includes(body.albumType)) errors.albumType = 'Выберите тип: studio, live, EP или single';
    const year = num(body.year);
    if (!Number.isInteger(year) || year < 1960 || year > 2100) errors.year = 'Год не меньше 1960';
    if (label.length < 2 || label.length > 80) errors.label = 'Лейбл: от 2 до 80 символов';
    if (str(body.coverUrl).length > 200) errors.coverUrl = 'Максимум символов: 200';
  }

  if (collection === 'members') {
    if (str(body.firstName).length < 2) errors.firstName = 'Укажите имя';
    if (str(body.lastName).length < 2) errors.lastName = 'Укажите фамилию';
    if (!str(body.role)) errors.role = 'Укажите роль';
    const years = num(body.yearsInBand);
    if (!Number.isInteger(years) || years < 0 || years > 80) errors.yearsInBand = 'Некорректный стаж';
    const fee = num(body.fee);
    if (!Number.isInteger(fee) || fee < 0) errors.fee = 'Гонорар — целое неотрицательное число';
    const email = str(body.email).toLowerCase();
    if (!emailOk(email)) errors.email = 'Введите корректный адрес почты';
    else if (db.members.some((row) => same(row) && row.email.toLowerCase() === email)) {
      errors.email = 'Участник с такой почтой уже есть';
    }
    const mask = str(body.maskCode).toUpperCase();
    if (!codeOk(mask, 3, 20)) errors.maskCode = 'Код маски: латиница, цифры и дефис';
    else if (db.members.some((row) => same(row) && row.maskCode.toUpperCase() === mask)) {
      errors.maskCode = 'Такой код маски уже назначен';
    }
    const albumIds = ids(body.albumIds);
    if (!albumIds.length) errors.albumIds = 'Выберите хотя бы один альбом';
    else if (albumIds.some((albumId) => !findActive('albums', albumId))) {
      errors.albumIds = 'Выберите существующие активные альбомы';
    }
    if (id && !errors.albumIds) {
      const blocked = db.concerts.some((concert) =>
        !concert.deletedAt &&
        (concert.memberIds || []).includes(id) &&
        !albumIds.includes(concert.albumId));
      if (blocked) {
        errors.albumIds = 'Нельзя убрать альбом, пока участник заявлен на его концерты';
      }
    }
  }

  if (collection === 'tracks') {
    if (!str(body.title)) errors.title = 'Укажите название';
    const trackNumber = num(body.trackNumber);
    if (!Number.isInteger(trackNumber) || trackNumber < 1 || trackNumber > 40) {
      errors.trackNumber = 'Номер не меньше 1';
    }
    const duration = num(body.durationSeconds);
    if (!Number.isInteger(duration) || duration < 10 || duration > 1200) {
      errors.durationSeconds = 'Длительность не меньше 10';
    }
    if (str(body.genre).length < 2) errors.genre = 'Укажите жанр';
    if (!findActive('albums', body.albumId)) errors.albumId = 'Выберите существующий активный альбом';
    if (!errors.trackNumber && !errors.albumId) {
      const duplicate = db.tracks.some((row) =>
        same(row) && row.albumId === Number(body.albumId) && row.trackNumber === trackNumber);
      if (duplicate) errors.trackNumber = 'В этом альбоме уже есть трек с таким номером';
    }
  }

  if (collection === 'merch') {
    if (str(body.name).length < 2) errors.name = 'Укажите название';
    const sku = str(body.sku).toUpperCase();
    if (!codeOk(sku, 3, 20)) errors.sku = 'Артикул: латиница, цифры и дефис';
    else if (db.merch.some((row) => same(row) && row.sku.toUpperCase() === sku)) {
      errors.sku = 'Товар с таким артикулом уже есть';
    }
    if (!str(body.category)) errors.category = 'Укажите категорию';
    const stock = num(body.stock);
    const price = num(body.price);
    if (!Number.isInteger(stock) || stock < 0) errors.stock = 'Остаток — целое неотрицательное число';
    if (!Number.isInteger(price) || price < 0) errors.price = 'Цена — целое неотрицательное число';
    if (!findActive('albums', body.albumId)) errors.albumId = 'Выберите существующий активный альбом';
  }

  if (collection === 'concerts') {
    if (str(body.city).length < 2) errors.city = 'Укажите город';
    if (str(body.venue).length < 2) errors.venue = 'Укажите площадку';
    if (!dayOf(body.date) || Number.isNaN(Date.parse(body.date))) errors.date = 'Укажите дату';
    const price = num(body.ticketPrice);
    if (!Number.isInteger(price) || price < 0) errors.ticketPrice = 'Цена билета — целое неотрицательное число';
    if (!CONCERT_STATUSES.includes(body.status)) errors.status = 'Статус: plan, done или cancelled';
    if (!findActive('albums', body.albumId)) errors.albumId = 'Выберите существующий активный альбом';
    const memberIds = ids(body.memberIds);
    if (!memberIds.length) errors.memberIds = 'Выберите хотя бы одного участника';
    else if (memberIds.some((memberId) => {
      const member = findActive('members', memberId);
      return !member || ((member.albumIds || []).length && !(member.albumIds || []).includes(Number(body.albumId)));
    })) {
      errors.memberIds = 'Участник не записан на выбранном альбоме';
    }
    const code = str(body.ticketCode).toUpperCase();
    if (!codeOk(code, 4, 20)) errors.ticketCode = 'Код билета: латиница, цифры и дефис';
    else if (db.concerts.some((row) => same(row) && row.ticketCode.toUpperCase() === code)) {
      errors.ticketCode = 'Билет с таким кодом уже существует';
    }
    const email = str(body.contactEmail);
    if (email && !emailOk(email)) errors.contactEmail = 'Введите корректный адрес почты';
  }

  return errors;
}

function concertConflict(body, id = null) {
  if (body.status === 'cancelled') return null;
  const day = dayOf(body.date);
  const venue = str(body.venue).toLowerCase();
  const others = db.concerts.filter((row) =>
    row.id !== id &&
    !row.deletedAt &&
    row.status !== 'cancelled' &&
    dayOf(row.date) === day);
  if (others.some((row) => str(row.venue).toLowerCase() === venue)) {
    return 'На эту дату площадка уже занята другим концертом';
  }
  const requested = ids(body.memberIds);
  if (others.some((row) => (row.memberIds || []).some((memberId) => requested.includes(memberId)))) {
    return 'Участник уже заявлен на другой концерт в этот день';
  }
  return null;
}

function deletionConflict(collection, targetIds, hard = false) {
  if (collection === 'albums') {
    const trackCount = db.tracks.filter((row) => active(row, hard) && targetIds.includes(row.albumId)).length;
    const merchCount = db.merch.filter((row) => active(row, hard) && targetIds.includes(row.albumId)).length;
    const concertCount = db.concerts.filter((row) => active(row, hard) && targetIds.includes(row.albumId)).length;
    const count = trackCount + merchCount + concertCount;
    if (count > 0) {
      return `Нельзя удалить альбом: связанных треков — ${trackCount}, мерча — ${merchCount}, концертов — ${concertCount}`;
    }
  }
  if (collection === 'members') {
    const count = db.concerts.filter((row) =>
      active(row, hard) && (row.memberIds || []).some((id) => targetIds.includes(id))).length;
    if (count > 0) return `Нельзя удалить участника: связанных концертов — ${count}`;
  }
  return null;
}

function normalize(collection, body) {
  if (collection === 'albums') {
    return {
      title: str(body.title),
      catalogCode: str(body.catalogCode).toUpperCase(),
      albumType: body.albumType,
      year: num(body.year),
      label: str(body.label),
      coverUrl: str(body.coverUrl),
    };
  }
  if (collection === 'members') {
    return {
      firstName: str(body.firstName),
      lastName: str(body.lastName),
      role: str(body.role),
      yearsInBand: num(body.yearsInBand),
      fee: num(body.fee),
      email: str(body.email),
      bio: str(body.bio),
      photoUrl: str(body.photoUrl),
      joinedYear: num(body.joinedYear) || 0,
      stageName: str(body.stageName),
      maskCode: str(body.maskCode).toUpperCase(),
      appointedOn: str(body.appointedOn),
      albumIds: ids(body.albumIds),
    };
  }
  if (collection === 'tracks') {
    return {
      title: str(body.title),
      trackNumber: num(body.trackNumber),
      durationSeconds: num(body.durationSeconds),
      genre: str(body.genre),
      albumId: Number(body.albumId),
    };
  }
  if (collection === 'merch') {
    return {
      name: str(body.name),
      sku: str(body.sku).toUpperCase(),
      category: str(body.category),
      stock: num(body.stock),
      price: num(body.price),
      sizeIds: ids(body.sizeIds),
      albumId: Number(body.albumId),
    };
  }
  const date = str(body.date);
  return {
    city: str(body.city),
    venue: str(body.venue),
    date: date.length === 10 ? `${date}T00:00:00.000Z` : new Date(date).toISOString(),
    ticketPrice: num(body.ticketPrice),
    status: body.status,
    albumId: Number(body.albumId),
    memberIds: ids(body.memberIds),
    ticketCode: str(body.ticketCode).toUpperCase(),
    contactEmail: str(body.contactEmail),
  };
}

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', ORIGIN);
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Max-Age', '86400');
  res.setHeader('Vary', 'Origin');
}

function send(res, status, payload) {
  cors(res);
  if (payload === undefined || status === 204) {
    res.writeHead(status === 204 ? 204 : status);
    res.end();
    return;
  }
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

function fail(res, status, message) {
  send(res, status, { message });
}

async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  if (!chunks.length) return {};
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    return null;
  }
}

function nextId(collection) {
  return db[collection].reduce((max, row) => Math.max(max, row.id), 0) + 1;
}

async function handle(req, res, url) {
  const query = Object.fromEntries(url.searchParams.entries());
  const path = url.pathname.replace(/\/+$/, '') || '/';
  const method = req.method.toUpperCase();

  if (query.__fail) {
    return fail(res, Number(query.__fail), 'Ошибка вызвана намеренно параметром __fail');
  }

  if (path === '/api/__health' && method === 'GET') {
    return send(res, 200, { status: 'ok', service: 'ghost', time: new Date().toISOString() });
  }

  if (path === '/api/__reset' && method === 'POST') {
    fresh();
    return send(res, 200, { message: 'Данные восстановлены в исходное состояние' });
  }

  if (path === '/api' && method === 'GET') {
    return send(res, 200, {
      service: 'Учебное API группы Ghost',
      collections: COLLECTIONS,
      endpoints: {
        'GET /api/:collection': 'Страница, поиск, фильтры, сортировка',
        'GET /api/:collection/:id': 'Одна запись',
        'POST /api/:collection': 'Создание',
        'PUT /api/:collection/:id': 'Изменение',
        'DELETE /api/:collection/:id': 'Логическое удаление',
        'DELETE /api/:collection/:id?hard=true': 'Физическое удаление',
        'POST /api/:collection/bulk-delete': 'Множественное удаление',
        'POST /api/:collection/:id/restore': 'Восстановление',
        'GET /api/__health': 'Проверка доступности',
        'POST /api/__reset': 'Сброс к исходным данным',
      },
    });
  }

  const bulk = path.match(/^\/api\/([a-z]+)\/bulk-delete$/);
  if (bulk && method === 'POST') {
    const collection = bulk[1];
    if (!COLLECTIONS.includes(collection)) return fail(res, 404, 'Ресурс не найден');
    const body = await readBody(req);
    const targetIds = Array.isArray(body && body.ids) ? body.ids.map(Number) : [];
    if (!targetIds.length) {
      return send(res, 422, { message: 'Ошибка валидации', errors: { ids: 'Передайте непустой список идентификаторов' } });
    }
    const hard = query.hard === 'true';
    const conflict = deletionConflict(collection, targetIds, hard);
    if (conflict) return fail(res, 409, conflict);
    if (hard) {
      const before = db[collection].length;
      db[collection] = db[collection].filter((row) => !targetIds.includes(row.id));
      return send(res, 200, { deleted: before - db[collection].length });
    }
    let deleted = 0;
    for (const row of db[collection]) {
      if (targetIds.includes(row.id) && !row.deletedAt) {
        row.deletedAt = new Date().toISOString();
        deleted += 1;
      }
    }
    return send(res, 200, { deleted });
  }

  const match = path.match(/^\/api\/([a-z]+)(?:\/(\d+))?(?:\/(restore))?$/);
  if (!match) return fail(res, 404, `Адрес ${method} ${path} не обслуживается`);

  const collection = match[1];
  const id = match[2] ? Number(match[2]) : null;
  const action = match[3] || null;
  if (!COLLECTIONS.includes(collection)) return fail(res, 404, 'Ресурс не найден');
  const expand = EXPANDERS[collection];

  if (action === 'restore' && method === 'POST') {
    const row = db[collection].find((item) => item.id === id);
    if (!row) return fail(res, 404, 'Объект не найден');
    const errors = validate(collection, row, id);
    if (Object.keys(errors).length) return send(res, 422, { message: 'Ошибка валидации', errors });
    if (collection === 'concerts') {
      const conflict = concertConflict(row, id);
      if (conflict) return fail(res, 409, conflict);
    }
    row.deletedAt = null;
    return send(res, 200, expand(row));
  }

  if (id === null && method === 'GET') {
    let rows = db[collection];
    if (query.includeDeleted !== 'true') rows = rows.filter((row) => !row.deletedAt);
    rows = applySort(applyFilters(collection, rows, query), query.sort);
    const page = paginate(rows, query);
    return send(res, 200, { ...page, items: page.items.map(expand) });
  }

  if (id !== null && method === 'GET') {
    const row = db[collection].find((item) => item.id === id);
    if (!row) return fail(res, 404, 'Объект не найден');
    return send(res, 200, expand(row));
  }

  if (id === null && method === 'POST') {
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
    const errors = validate(collection, body);
    if (Object.keys(errors).length) return send(res, 422, { message: 'Ошибка валидации', errors });
    if (collection === 'concerts') {
      const conflict = concertConflict(body);
      if (conflict) return fail(res, 409, conflict);
    }
    const row = { id: nextId(collection), ...normalize(collection, body), deletedAt: null };
    db[collection].push(row);
    return send(res, 201, expand(row));
  }

  if (id !== null && (method === 'PUT' || method === 'PATCH')) {
    const row = db[collection].find((item) => item.id === id && !item.deletedAt);
    if (!row) return fail(res, 404, 'Объект не найден');
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
    const merged = method === 'PATCH' ? { ...row, ...body } : body;
    const errors = validate(collection, merged, id);
    if (Object.keys(errors).length) return send(res, 422, { message: 'Ошибка валидации', errors });
    if (collection === 'concerts') {
      const conflict = concertConflict(merged, id);
      if (conflict) return fail(res, 409, conflict);
    }
    Object.assign(row, normalize(collection, merged));
    return send(res, 200, expand(row));
  }

  if (id !== null && method === 'DELETE') {
    const index = db[collection].findIndex((item) => item.id === id);
    if (index < 0) return fail(res, 404, 'Объект не найден');
    const hard = query.hard === 'true';
    const conflict = deletionConflict(collection, [id], hard);
    if (conflict) return fail(res, 409, conflict);
    if (hard) db[collection].splice(index, 1);
    else db[collection][index].deletedAt = new Date().toISOString();
    return send(res, 204);
  }

  return fail(res, 404, `Адрес ${method} ${path} не обслуживается`);
}

fresh();
const dataFile = nodePath.join(__dirname, '.local-state.json');
const ephemeral = args.includes('--ephemeral');

function saveData() {
  if (ephemeral) return;
  fs.writeFileSync(`${dataFile}.tmp`, JSON.stringify(db));
  fs.renameSync(`${dataFile}.tmp`, dataFile);
}

if (!ephemeral && fs.existsSync(dataFile)) {
  db = JSON.parse(fs.readFileSync(dataFile, 'utf8'));
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  if (req.method === 'OPTIONS') {
    cors(res);
    res.writeHead(204);
    return res.end();
  }
  const delay = Number(url.searchParams.get('__delay') || 0);
  if (delay > 0) await new Promise((resolve) => setTimeout(resolve, Math.min(delay, 10000)));
  const started = Date.now();
  try {
    await handle(req, res, url);
    if (!['GET', 'HEAD', 'OPTIONS'].includes(req.method) && res.statusCode < 400) saveData();
  } catch (error) {
    console.error(error);
    if (!res.headersSent) fail(res, 500, `Внутренняя ошибка сервера: ${error.message}`);
  }
  console.log(`${req.method.padEnd(6)} ${url.pathname}${url.search} → ${res.statusCode} ${Date.now() - started} мс`);
});

server.listen(PORT, () => {
  console.log('');
  console.log('  Учебное API группы Ghost');
  console.log(`  Адрес:                http://localhost:${PORT}/api`);
  console.log(`  Разрешённый источник: ${ORIGIN}`);
  console.log('  Проверка:             GET /api/__health');
  console.log('  Сброс данных:         POST /api/__reset');
  console.log('');
});
