// ─── Data models ───────────────────────────────────────────────────────────

class PostModel {
  final String id;
  final String name;
  final String handle;
  final String time;
  final String place;
  final String drink;
  final String caption;
  final int cheers;
  final int comments;
  final bool mine;
  final String tone;       // ImgTone key
  final String selfieTone; // ImgTone key
  final bool late;

  const PostModel({
    required this.id,
    required this.name,
    required this.handle,
    required this.time,
    required this.place,
    required this.drink,
    this.caption = '',
    required this.cheers,
    required this.comments,
    this.mine = false,
    required this.tone,
    required this.selfieTone,
    this.late = false,
  });
}

class FriendModel {
  final String name;
  final String status;
  final bool online;
  final String tone;

  const FriendModel({
    required this.name,
    required this.status,
    required this.online,
    required this.tone,
  });
}

class MapPin {
  final double lat;
  final double lng;
  final String label;
  final String drink;
  final bool isYou;

  const MapPin({
    required this.lat,
    required this.lng,
    required this.label,
    required this.drink,
    this.isYou = false,
  });
}

// ─── Sample data ───────────────────────────────────────────────────────────

const friendsFeed = <PostModel>[
  PostModel(
    id: 'p1', name: 'Maya Calderón', handle: '@mayac', time: '12m',
    place: 'The Goose & Crown · SE15', drink: 'Hazy Pale · 5.2%',
    caption: 'first one after the marathon. earned.',
    cheers: 24, comments: 6, tone: 'beer', selfieTone: 'selfie',
  ),
  PostModel(
    id: 'p2', name: 'Theo Park', handle: '@theop', time: '31m',
    place: 'Allagash Taproom · Portland', drink: 'Triple Belgian · 9.5%',
    caption: 'research purposes.',
    cheers: 41, comments: 12, tone: 'bar', selfieTone: 'selfie',
  ),
  PostModel(
    id: 'p3', name: 'Priya Anand', handle: '@priyaa', time: '1h 02m',
    place: 'Home · Brooklyn', drink: 'Pilsner Urquell',
    caption: 'tuesday. you know how it is.',
    cheers: 18, comments: 3, tone: 'sky', selfieTone: 'selfie', late: true,
  ),
  PostModel(
    id: 'p4', name: 'Jonas Lindqvist', handle: '@jlind', time: '1h 47m',
    place: 'Mikkeller · Reykjavík', drink: 'Imperial Stout · 11%',
    caption: 'the menu has 87 entries. i have all night.',
    cheers: 67, comments: 21, tone: 'night', selfieTone: 'selfie', late: true,
  ),
];

const friendsList = <FriendModel>[
  FriendModel(name: 'Maya Calderón',   status: 'Poured · 12m ago',          online: true,  tone: 'avatar'),
  FriendModel(name: 'Theo Park',       status: 'Poured · 31m ago',          online: true,  tone: 'selfie'),
  FriendModel(name: 'Priya Anand',     status: 'Poured · 1h ago',           online: false, tone: 'avatar'),
  FriendModel(name: 'Jonas Lindqvist', status: 'Poured · 1h ago',           online: true,  tone: 'selfie'),
  FriendModel(name: 'Sam Okafor',      status: 'Waiting for prompt',        online: true,  tone: 'avatar'),
  FriendModel(name: 'Hana Tsuji',      status: 'Waiting for prompt',        online: false, tone: 'selfie'),
  FriendModel(name: 'Rafael Costa',    status: 'Last poured · yesterday',   online: false, tone: 'avatar'),
  FriendModel(name: 'Lena Bauer',      status: 'Last poured · 2d ago',      online: true,  tone: 'selfie'),
];

const mapPins = <MapPin>[
  MapPin(lat: 40.7228, lng: -73.9846, label: 'Maya',  drink: 'Hazy Pale'),
  MapPin(lat: 40.7282, lng: -74.0030, label: 'Theo',  drink: 'Triple'),
  MapPin(lat: 40.6892, lng: -73.9442, label: 'Priya', drink: 'Pilsner'),
  MapPin(lat: 40.7350, lng: -73.9900, label: 'Jonas', drink: 'Stout'),
  MapPin(lat: 40.6770, lng: -73.9500, label: 'you',   drink: '—', isYou: true),
];

List<int> buildStreakGrid() {
  final out = <int>[];
  for (var i = 0; i < 84; i++) {
    final r = (i * 37 + 13) % 100;
    var v = 0;
    if (r > 70) { v = 3; }
    else if (r > 50) { v = 2; }
    else if (r > 30) { v = 1; }
    if (i >= 78 && r > 40 && v < 2) { v = 2; }
    if (i == 83) { v = 0; }
    out.add(v);
  }
  return out;
}
