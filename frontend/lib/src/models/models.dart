class Message {
  final int? id;
  final int chatId;
  final int? senderId;
  final int receiverId;
  final String content;
  final DateTime? time;
  final bool? isRead;

  Message({
    this.id,
    required this.chatId,
    this.senderId,
    required this.receiverId,
    required this.content,
    this.time,
    this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'],
    chatId: json['chat_id'],
    senderId: json['sender_id'],
    receiverId: json['receiver_id'],
    content: json['content'],
    time: DateTime.parse(json['time']),
    isRead: json['is_read'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'chat_id': chatId,
    'sender_id': senderId,
    'receiver_id': receiverId,
    'content': content,
    'time': time?.toIso8601String(),
    'is_read': isRead,
  };
}

class Chat {
  final int id;
  final int userId1;
  final int userId2;

  Chat({required this.id, required this.userId1, required this.userId2});

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
    id: json['id'],
    userId1: json['user1_id'],
    userId2: json['user2_id'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user1_id': userId1,
    'user2_id': userId2,
  };
}

class ChatSummary {
  final int id;
  final int userId;
  final String name;
  final String profileUrl;
  String lastMessage;
  bool read;
  DateTime time;

  ChatSummary({
    required this.id,
    required this.userId,
    required this.name,
    required this.profileUrl,
    required this.lastMessage,
    required this.read,
    required this.time,
  });

  factory ChatSummary.fromJson(Map<String, dynamic> json) => ChatSummary(
    id: json['id'],
    userId: json['user_id'],
    name: json['name'],
    profileUrl: json['profile_url'],
    lastMessage: json['last_message'],
    read: json['read'],
    time: DateTime.parse(json['time']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'profile_url': profileUrl,
    'last_message': lastMessage,
    'read': read,
    'time': time.toIso8601String(),
  };
}

class Match {
  final int id;
  final int userId1;
  final int userId2;

  Match({required this.id, required this.userId1, required this.userId2});

  factory Match.fromJson(Map<String, dynamic> json) => Match(
    id: json['id'],
    userId1: json['user1_id'],
    userId2: json['user2_id'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user1_id': userId1,
    'user2_id': userId2,
  };
}

class MatchSummary {
  final int id;
  final int userId;
  final String name;
  final String profileUrl;

  MatchSummary({
    required this.id,
    required this.userId,
    required this.name,
    required this.profileUrl,
  });

  factory MatchSummary.fromJson(Map<String, dynamic> json) => MatchSummary(
    id: json['id'],
    userId: json['user_id'],
    name: json['name'],
    profileUrl: json['profile_url'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'profile_url': profileUrl,
  };
}

class User {
  final int id;
  final String name;
  final String gender;
  final DateTime birthday;
  final String profileUrl;
  final List<String> imagesUrl;
  final String bio;
  final String country;

  User({
    required this.id,
    required this.name,
    required this.gender,
    required this.birthday,
    required this.profileUrl,
    required this.imagesUrl,
    required this.bio,
    required this.country,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    name: json['name'],
    gender: json['gender'],
    birthday: DateTime.parse(json['birthday']),
    profileUrl: json['profile_url'],
    imagesUrl: List<String>.from(json['images_url']),
    bio: json['bio'],
    country: json['country'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gender': gender,
    'birthday': birthday.toIso8601String(),
    'profile_url': profileUrl,
    'images_url': imagesUrl,
    'bio': bio,
    'country': country,
  };
}

class UserExploreSummary {
  final int id;
  final String name;
  final int age;
  final String profileUrl;
  final List<String> imagesUrl;
  final String bio;
  final String country;

  UserExploreSummary({
    required this.id,
    required this.name,
    required this.age,
    required this.profileUrl,
    required this.imagesUrl,
    required this.bio,
    required this.country,
  });

  factory UserExploreSummary.fromJson(Map<String, dynamic> json) =>
      UserExploreSummary(
        id: json['id'],
        name: json['name'],
        age: json['age'],
        profileUrl: json['profile_url'],
        imagesUrl: List<String>.from(json['images_url']),
        bio: json['bio'],
        country: json['country'],
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'profile_url': profileUrl,
    'images_url': imagesUrl,
    'bio': bio,
    'country': country,
  };
}

class Opinion {
  final int? id;
  final int senderId;
  final int receiverId;
  final String opinion;
  final DateTime? createdAt;

  Opinion({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.opinion,
    this.createdAt,
  });

  factory Opinion.fromJson(Map<String, dynamic> json) => Opinion(
    id: json['id'],
    senderId: json['sender_id'],
    receiverId: json['receiver_id'],
    opinion: json['opinion'],
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender_id': senderId,
    'receiver_id': receiverId,
    'opinion': opinion,
    'created_at': createdAt?.toIso8601String(),
  };
}

class OpinionSummary {
  final int id;
  final int senderId;
  final String opinion;
  final String name;
  final String profileUrl;
  final DateTime createdAt;

  OpinionSummary({
    required this.id,
    required this.senderId,
    required this.opinion,
    required this.name,
    required this.profileUrl,
    required this.createdAt,
  });

  factory OpinionSummary.fromJson(Map<String, dynamic> json) => OpinionSummary(
    id: json['id'],
    senderId: json['sender_id'],
    opinion: json['opinion'],
    name: json['name'],
    profileUrl: json['profile_url'],
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender_id': senderId,
    'opinion': opinion,
    'name': name,
    'profile_url': profileUrl,
    'created_at': createdAt.toIso8601String(),
  };
}

class Skip {
  final int? id;
  final int skipperId;
  final int skippedId;

  Skip({this.id, required this.skipperId, required this.skippedId});

  factory Skip.fromJson(Map<String, dynamic> json) => Skip(
    id: json['id'],
    skipperId: json['skipper'],
    skippedId: json['skipped'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'skipper': skipperId,
    'skipped': skippedId,
  };
}
