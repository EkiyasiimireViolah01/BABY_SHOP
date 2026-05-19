class FeedbackMessage {
  final String id;
  final String customerName;
  final String customerEmail;
  final String message;
  final String date;
  String status;
  String? reply;

  FeedbackMessage({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.message,
    required this.date,
    required this.status,
    this.reply,
  });

  // Convert to JSON for sending to backend
  Map<String, dynamic> toJson() => {
    '_id': id,
    'customerName': customerName,
    'customerEmail': customerEmail,
    'message': message,
    'date': date,
    'status': status,
    'reply': reply,
    'createdAt': date,
  };

  // Create from JSON returned by backend
  factory FeedbackMessage.fromJson(Map<String, dynamic> json) {
    return FeedbackMessage(
      id: json['_id']?.toString()?? json['id']?.toString()?? '',
      customerName: json['customerName']?.toString()?? '',
      customerEmail: json['customerEmail']?.toString()?? '',
      message: json['message']?.toString()?? '',
      date: json['date']?.toString()??
            json['createdAt']?.toString()??
            DateTime.now().toIso8601String().split('T')[0],
      status: json['status']?.toString()?? 'New',
      reply: json['reply']?.toString(),
    );
  }

  // Helper to create updated copy after admin replies
  FeedbackMessage copyWith({
    String? status,
    String? reply,
  }) {
    return FeedbackMessage(
      id: id,
      customerName: customerName,
      customerEmail: customerEmail,
      message: message,
      date: date,
      status: status?? this.status,
      reply: reply?? this.reply,
    );
  }

  @override
  String toString() {
    return 'FeedbackMessage(id: $id, customerName: $customerName, status: $status, reply: $reply)';
  }
}