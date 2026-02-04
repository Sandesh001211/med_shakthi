class B2BProductFilter {
  String? sortBy; // price_low | price_high

  bool expiry3Months = false;
  bool expiry6Months = false;

  B2BProductFilter();

  DateTime? get expiryBefore {
    final now = DateTime.now();
    if (expiry3Months) {
      return DateTime(now.year, now.month + 3, now.day);
    }
    if (expiry6Months) {
      return DateTime(now.year, now.month + 6, now.day);
    }
    return null;
  }
}
