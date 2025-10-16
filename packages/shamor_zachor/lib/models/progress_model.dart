/// Represents the progress for a single page/item
/// Includes initial learning and up to 3 reviews
class PageProgress {
  bool learn;
  bool review1;
  bool review2;
  bool review3;

  PageProgress({
    this.learn = false,
    this.review1 = false,
    this.review2 = false,
    this.review3 = false,
  });

  /// Convert to JSON for storage
  Map<String, bool> toJson() => {
        'learn': learn,
        'review1': review1,
        'review2': review2,
        'review3': review3,
      };

  /// Create from JSON data
  factory PageProgress.fromJson(Map<String, dynamic> json) {
    return PageProgress(
      learn: json['learn'] ?? false,
      review1: json['review1'] ?? false,
      review2: json['review2'] ?? false,
      review3: json['review3'] ?? false,
    );
  }

  /// Check if no progress has been made
  bool get isEmpty => !learn && !review1 && !review2 && !review3;

  /// Check if all learning and reviews are complete
  bool get isComplete => learn && review1 && review2 && review3;

  /// Get the number of completed items (learn + reviews)
  int get completedCount {
    int count = 0;
    if (learn) count++;
    if (review1) count++;
    if (review2) count++;
    if (review3) count++;
    return count;
  }

  /// Get progress as a percentage (0.0 to 1.0)
  double get progressPercentage => completedCount / 4.0;

  /// Set a specific property by name
  void setProperty(String propertyName, bool value) {
    switch (propertyName) {
      case 'learn':
        learn = value;
        break;
      case 'review1':
        review1 = value;
        break;
      case 'review2':
        review2 = value;
        break;
      case 'review3':
        review3 = value;
        break;
      default:
        throw ArgumentError('Unknown property: $propertyName');
    }
  }

  /// Get a specific property by name
  bool getProperty(String propertyName) {
    switch (propertyName) {
      case 'learn':
        return learn;
      case 'review1':
        return review1;
      case 'review2':
        return review2;
      case 'review3':
        return review3;
      default:
        throw ArgumentError('Unknown property: $propertyName');
    }
  }

  /// Create a copy with modified values
  PageProgress copyWith({
    bool? learn,
    bool? review1,
    bool? review2,
    bool? review3,
  }) {
    return PageProgress(
      learn: learn ?? this.learn,
      review1: review1 ?? this.review1,
      review2: review2 ?? this.review2,
      review3: review3 ?? this.review3,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageProgress &&
          runtimeType == other.runtimeType &&
          learn == other.learn &&
          review1 == other.review1 &&
          review2 == other.review2 &&
          review3 == other.review3;

  @override
  int get hashCode =>
      learn.hashCode ^ review1.hashCode ^ review2.hashCode ^ review3.hashCode;

  @override
  String toString() {
    return 'PageProgress(learn: $learn, review1: $review1, review2: $review2, review3: $review3)';
  }
}

/// Type definitions for complex progress data structures

/// Full progress map: Category -> Book -> Page/Item -> Progress
typedef FullProgressMap = Map<String, Map<String, Map<String, PageProgress>>>;

/// Completion dates map: Category -> Book -> Completion Date (Hebrew)
typedef CompletionDatesMap = Map<String, Map<String, String>>;

/// Book progress summary for display purposes
class BookProgressSummary {
  final String categoryName;
  final String bookName;
  final int totalItems;
  final int completedItems;
  final int inProgressItems;
  final String? completionDate;
  final DateTime? lastAccessed;
  final bool isActiveReview;

  const BookProgressSummary({
    required this.categoryName,
    required this.bookName,
    required this.totalItems,
    required this.completedItems,
    required this.inProgressItems,
    this.completionDate,
    this.lastAccessed,
    this.isActiveReview = false,
  });

  /// Get progress as a percentage (0.0 to 1.0)
  double get progressPercentage =>
      totalItems > 0 ? completedItems / totalItems : 0.0;

  /// Check if the book is completed
  bool get isCompleted => completedItems == totalItems && totalItems > 0;

  /// Check if the book has any progress
  bool get hasProgress => completedItems > 0 || inProgressItems > 0;

  /// Get status text for display
  String get statusText {
    if (totalItems <= 0) {
      return 'לימוד פעיל';
    }
    if (isActiveReview) return 'בחזרה';
    final progress = progressPercentage;
    if (progress >= 1.0) {
      return 'מוכן לחזרה';
    }
    if (progress > 0.8) {
      return 'כמעט סיום';
    }
    if (progress > 0.5) {
      return 'באמצע הדרך';
    }
    if (progress > 0) {
      return 'בתחילת הדרך';
    }
    return 'לא התחיל';
  }

  /// Create a modified copy of this summary.
  BookProgressSummary copyWith({
    int? totalItems,
    int? completedItems,
    int? inProgressItems,
    String? completionDate,
    DateTime? lastAccessed,
    bool? isActiveReview,
  }) {
    return BookProgressSummary(
      categoryName: categoryName,
      bookName: bookName,
      totalItems: totalItems ?? this.totalItems,
      completedItems: completedItems ?? this.completedItems,
      inProgressItems: inProgressItems ?? this.inProgressItems,
      completionDate: completionDate ?? this.completionDate,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      isActiveReview: isActiveReview ?? this.isActiveReview,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookProgressSummary &&
          runtimeType == other.runtimeType &&
          categoryName == other.categoryName &&
          bookName == other.bookName &&
          totalItems == other.totalItems &&
          completedItems == other.completedItems &&
          inProgressItems == other.inProgressItems &&
          completionDate == other.completionDate &&
          lastAccessed == other.lastAccessed &&
          isActiveReview == other.isActiveReview;

  @override
  int get hashCode =>
      categoryName.hashCode ^
      bookName.hashCode ^
      totalItems.hashCode ^
      completedItems.hashCode ^
      inProgressItems.hashCode ^
      completionDate.hashCode ^
      lastAccessed.hashCode ^
      isActiveReview.hashCode;

  @override
  String toString() {
    return 'BookProgressSummary(categoryName: $categoryName, bookName: $bookName, '
        'progress: $completedItems/$totalItems, activeReview: $isActiveReview, '
        'status: $statusText)';
  }
}
