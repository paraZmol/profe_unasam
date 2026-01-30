enum ReviewFlagStatus { pending, approved, rejected }

class ReviewFlag {
  final String id;
  final String reviewId;
  final String profesorId;
  final String reason;
  final String flaggedByUserId;
  final DateTime createdAt;
  final Set<String> moderatorApprovals;
  final bool adminApproved;
  final ReviewFlagStatus status;

  ReviewFlag({
    required this.id,
    required this.reviewId,
    required this.profesorId,
    required this.reason,
    required this.flaggedByUserId,
    required this.createdAt,
    required this.moderatorApprovals,
    required this.adminApproved,
    required this.status,
  });

  ReviewFlag copyWith({
    String? id,
    String? reviewId,
    String? profesorId,
    String? reason,
    String? flaggedByUserId,
    DateTime? createdAt,
    Set<String>? moderatorApprovals,
    bool? adminApproved,
    ReviewFlagStatus? status,
  }) {
    return ReviewFlag(
      id: id ?? this.id,
      reviewId: reviewId ?? this.reviewId,
      profesorId: profesorId ?? this.profesorId,
      reason: reason ?? this.reason,
      flaggedByUserId: flaggedByUserId ?? this.flaggedByUserId,
      createdAt: createdAt ?? this.createdAt,
      moderatorApprovals: moderatorApprovals ?? this.moderatorApprovals,
      adminApproved: adminApproved ?? this.adminApproved,
      status: status ?? this.status,
    );
  }
}
