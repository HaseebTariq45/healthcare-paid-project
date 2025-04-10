import 'package:intl/intl.dart';

class DateFormatter {
  // Format DateTime to YYYY-MM-DD (for database storage)
  static String toYYYYMMDD(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
  
  // Parse YYYY-MM-DD to DateTime
  static DateTime fromYYYYMMDD(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) {
      throw FormatException('Invalid date format. Expected YYYY-MM-DD');
    }
    
    return DateTime(
      int.parse(parts[0]), 
      int.parse(parts[1]), 
      int.parse(parts[2]),
    );
  }
  
  // Format to user-friendly display (e.g., "Mon, 15 Jan 2023")
  static String toUserFriendly(DateTime date) {
    return DateFormat('EEE, d MMM yyyy').format(date);
  }
  
  // Format to "15 Jan 2023"
  static String toShortDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }
  
  // Format to weekday only (e.g., "Monday")
  static String toWeekday(DateTime date) {
    return DateFormat('EEEE').format(date);
  }
  
  // Format time to 12-hour format (e.g., "09:30 AM")
  static String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }
  
  // Check if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
  
  // Get a list of dates for the next N days from a start date
  static List<DateTime> getNextDays(DateTime startDate, int numberOfDays) {
    return List.generate(
      numberOfDays, 
      (index) => DateTime(
        startDate.year, 
        startDate.month, 
        startDate.day + index,
      ),
    );
  }
} 