function iso(year, month, day) {
  return new Date(Date.UTC(year, month - 1, day)).toISOString();
}

const albums = [
  [1, 'Opus Eponymous', 'GH-ALB-001', 'studio', 2010, 'Rise Above', 'covers/opus.jpg'],
  [2, 'Infestissumam', 'GH-ALB-002', 'studio', 2013, 'Loma Vista', 'covers/infest.jpg'],
  [3, 'Meliora', 'GH-ALB-003', 'studio', 2015, 'Loma Vista', 'covers/meliora.jpg'],
  [4, 'Prequelle', 'GH-ALB-004', 'studio', 2018, 'Loma Vista', 'covers/prequelle.jpg'],
  [5, 'Impera', 'GH-ALB-005', 'studio', 2022, 'Loma Vista', 'covers/impera.jpg'],
  [6, 'Phantomime', 'GH-ALB-006', 'EP', 2023, 'Loma Vista', 'covers/phantomime.jpg'],
  [7, 'Rite Here Rite Now', 'GH-ALB-007', 'live', 2024, 'Loma Vista', 'covers/rhrn.jpg'],
  [8, 'If You Have Ghost', 'GH-ALB-008', 'EP', 2013, 'Loma Vista', 'covers/iyhg.jpg'],
  [9, 'Popestar', 'GH-ALB-009', 'EP', 2016, 'Loma Vista', 'covers/popestar.jpg'],
  [10, 'Skeletá', 'GH-ALB-010', 'studio', 2025, 'Loma Vista', 'covers/skeleta.jpg'],
  [11, 'Ceremony and Devotion', 'GH-ALB-011', 'live', 2017, 'Loma Vista', 'covers/ceremony.jpg'],
  [12, 'Seven Inches of Satanic Panic', 'GH-ALB-012', 'single', 2019, 'Loma Vista', 'covers/seven.jpg'],
].map(([id, title, catalogCode, albumType, year, label, coverUrl]) => ({
  id, title, catalogCode, albumType, year, label, coverUrl, deletedAt: null,
}));

const members = [
  [1, 'Tobias', 'Forge', 'Вокал', 18, 90000, 'tobias.forge@ghost.band', 'Основатель Ghost и автор сценических пап.', 'photos/forge.jpg', 2008, 'Papa V Perpetua', 'PAPA-V', '2025-04-25', [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]],
  [2, 'Martin', 'Persner', 'Гитара', 8, 45000, 'martin.persner@ghost.band', 'Гитарист раннего состава, Nameless Ghoul Omega.', 'photos/persner.jpg', 2010, 'Omega', 'GH-OMEGA', '2010-10-18', [1, 2]],
  [3, 'Simon', 'Söderberg', 'Гитара', 6, 42000, 'simon.soderberg@ghost.band', 'Гитарист эпохи Opus и Meliora.', 'photos/soderberg.jpg', 2010, 'Alpha', 'GH-ALPHA', '2010-10-18', [1, 2, 3]],
  [4, 'Richard', 'Ottosson', 'Бас', 4, 38000, 'richard.ottosson@ghost.band', 'Бас ранних ритуалов.', 'photos/ottosson.jpg', 2010, 'Water', 'GH-WATER', '2011-03-01', [1, 2]],
  [5, 'Mauro', 'Rubino', 'Клавиши', 7, 40000, 'mauro.rubino@ghost.band', 'Клавишные и орган на Meliora и Prequelle.', 'photos/rubino.jpg', 2015, 'Air', 'GH-AIR', '2015-08-21', [3, 4]],
  [6, 'Ludvig', 'Kennberg', 'Ударные', 5, 41000, 'ludvig.kennberg@ghost.band', 'Ударные тура Meliora.', 'photos/kennberg.jpg', 2015, 'Earth', 'GH-EARTH', '2015-08-21', [3, 4]],
  [7, 'Henrik', 'Palm', 'Гитара', 3, 36000, 'henrik.palm@ghost.band', 'Гитара и бас переходного состава.', 'photos/palm.jpg', 2016, 'Fire', 'GH-FIRE', '2016-01-15', [2, 3]],
  [8, 'Per', 'Eriksson', 'Гитара', 4, 37000, 'per.eriksson@ghost.band', 'Гитарист ранних концертных записей.', 'photos/eriksson.jpg', 2010, 'Aether', 'GH-AETHER', '2010-12-01', [1, 2]],
  [9, 'Hayden', 'Scott', 'Ударные', 2, 33000, 'hayden.scott@ghost.band', 'Ударные тура Impera.', 'photos/scott.jpg', 2022, 'Mountain', 'GH-MOUNTAIN', '2022-03-11', [5, 6, 7]],
  [10, 'Cosmo', 'Sylvan', 'Бас', 2, 32000, 'cosmo.sylvan@ghost.band', 'Бас-гитара эпохи Impera.', 'photos/sylvan.jpg', 2022, 'Rain', 'GH-RAIN', '2022-03-11', [5, 6, 7]],
  [11, 'Chris', 'Catalyst', 'Гитара', 3, 35000, 'chris.catalyst@ghost.band', 'Соло-гитара Skeletour.', 'photos/catalyst.jpg', 2022, 'Sodo', 'GH-SODO', '2022-03-11', [5, 6, 7, 10]],
  [12, 'Sophie', 'Amelkin', 'Бэк-вокал', 1, 28000, 'sophie.amelkin@ghost.band', 'Бэк-вокал и хор на Skeletá.', 'photos/amelkin.jpg', 2025, 'Cumulus', 'GH-CUMULUS', '2025-04-25', [6, 7, 10]],
].map(([id, firstName, lastName, role, yearsInBand, fee, email, bio, photoUrl, joinedYear, stageName, maskCode, appointedOn, albumIds]) => ({
  id, firstName, lastName, role, yearsInBand, fee, email, bio, photoUrl, joinedYear, stageName, maskCode, appointedOn, albumIds, deletedAt: null,
}));

const tracks = [
  [1, 'Ritual', 2, 268, 'Doom metal', 1],
  [2, 'Elizabeth', 4, 241, 'Hard rock', 1],
  [3, 'Stand by Him', 6, 236, 'Hard rock', 1],
  [4, 'Year Zero', 5, 320, 'Heavy metal', 2],
  [5, 'Secular Haze', 2, 311, 'Psychedelic rock', 2],
  [6, 'Cirice', 3, 362, 'Heavy metal', 3],
  [7, 'From the Pinnacle to the Pit', 2, 242, 'Doom metal', 3],
  [8, 'He Is', 6, 253, 'Pop rock', 3],
  [9, 'Mummy Dust', 8, 247, 'Heavy metal', 3],
  [10, 'Rats', 2, 263, 'Hard rock', 4],
  [11, 'Dance Macabre', 4, 237, 'Pop rock', 4],
  [12, 'Kaisarion', 2, 305, 'Hard rock', 5],
  [13, 'Spillways', 4, 196, 'Pop rock', 5],
  [14, 'Call Me Little Sunshine', 5, 284, 'Hard rock', 5],
  [15, 'Jesus He Knows Me', 1, 246, 'Hard rock', 6],
  [16, 'Square Hammer (live)', 1, 258, 'Hard rock', 7],
  [17, 'If You Have Ghosts', 1, 214, 'Psychedelic rock', 8],
  [18, 'Square Hammer', 1, 239, 'Hard rock', 9],
  [19, 'Satanized', 1, 230, 'Hard rock', 10],
  [20, 'Lachryma', 2, 248, 'Pop rock', 10],
  [21, 'Kiss the Go-Goat', 1, 197, 'Psychedelic rock', 12],
].map(([id, title, trackNumber, durationSeconds, genre, albumId]) => ({
  id, title, trackNumber, durationSeconds, genre, albumId, deletedAt: null,
}));

const merch = [
  [1, 'Футболка Meliora', 'GH-001', 'Одежда', 24, 2500, [1, 2], 3],
  [2, 'Худи Opus Eponymous', 'GH-002', 'Одежда', 12, 4200, [1, 2, 3], 1],
  [3, 'Винил Prequelle', 'GH-003', 'Винил', 8, 3800, [4], 4],
  [4, 'Винил Impera', 'GH-004', 'Винил', 15, 3900, [4], 5],
  [5, 'Винил Infestissumam', 'GH-005', 'Винил', 5, 3600, [4], 2],
  [6, 'CD Meliora', 'GH-006', 'CD', 30, 900, [5], 3],
  [7, 'CD Phantomime', 'GH-007', 'CD', 18, 1100, [5], 6],
  [8, 'Постер Imperatour', 'GH-008', 'Постеры', 40, 700, [6], 5],
  [9, 'Постер Papa Emeritus', 'GH-009', 'Постеры', 22, 850, [6], 4],
  [10, 'Бейсболка Ghost', 'GH-010', 'Аксессуары', 17, 1600, [2], 5],
  [11, 'Значок Nameless Ghoul', 'GH-011', 'Аксессуары', 60, 350, [7], 3],
  [12, 'Футболка Papa Emeritus', 'GH-012', 'Одежда', 9, 2700, [1, 2], 5],
].map(([id, name, sku, category, stock, price, sizeIds, albumId]) => ({
  id, name, sku, category, stock, price, sizeIds, albumId, deletedAt: null,
}));

const concerts = [
  [1, 'Stockholm', 'Avicii Arena', iso(2026, 12, 12), 6500, 'plan', 10, [1, 11, 12], 'GH-STO-001', 'stockholm@ghost.band'],
  [2, 'London', 'The O2', iso(2026, 11, 28), 7200, 'plan', 10, [1, 11, 12], 'GH-LON-002', 'london@ghost.band'],
  [3, 'Berlin', 'Uber Eats Music Hall', iso(2026, 6, 3), 5900, 'done', 5, [1, 9, 10, 11], 'GH-BER-003', 'berlin@ghost.band'],
  [4, 'Paris', 'Accor Arena', iso(2026, 6, 18), 6100, 'done', 5, [1, 9, 10, 11], 'GH-PAR-004', 'paris@ghost.band'],
  [5, 'Los Angeles', 'Kia Forum', iso(2025, 9, 14), 8000, 'done', 7, [1, 9, 10, 11, 12], 'GH-LAX-005', 'la@ghost.band'],
  [6, 'New York', 'Madison Square Garden', iso(2025, 9, 21), 8500, 'done', 7, [1, 9, 10, 11, 12], 'GH-NYC-006', 'nyc@ghost.band'],
  [7, 'Oslo', 'Spektrum', iso(2027, 2, 4), 5400, 'plan', 10, [1, 11, 12], 'GH-OSL-007', 'oslo@ghost.band'],
  [8, 'Helsinki', 'Ice Hall', iso(2024, 5, 2), 4800, 'cancelled', 5, [1, 9, 10, 11], 'GH-HEL-008', 'helsinki@ghost.band'],
  [9, 'Rome', 'Palazzo dello Sport', iso(2018, 10, 9), 4200, 'done', 4, [1, 5, 6], 'GH-ROM-009', 'rome@ghost.band'],
  [10, 'Chicago', 'United Center', iso(2016, 4, 16), 3900, 'done', 3, [1, 3, 5, 6, 7], 'GH-CHI-010', 'chicago@ghost.band'],
  [11, 'Linköping', 'Saab Arena', iso(2011, 6, 11), 1800, 'done', 1, [1, 2, 3, 4, 8], 'GH-LKP-011', 'linkoping@ghost.band'],
  [12, 'Warsaw', 'Torwar', iso(2027, 3, 19), 4500, 'plan', 10, [1, 11, 12], 'GH-WAW-012', 'warsaw@ghost.band'],
].map(([id, city, venue, date, ticketPrice, status, albumId, memberIds, ticketCode, contactEmail]) => ({
  id, city, venue, date, ticketPrice, status, albumId, memberIds, ticketCode, contactEmail, deletedAt: null,
}));

module.exports = { albums, members, tracks, merch, concerts };
