import 'package:flutter/material.dart';

class DateRangeFilter extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?) onDateRangeChanged;

  const DateRangeFilter({
    super.key,
    this.startDate,
    this.endDate,
    required this.onDateRangeChanged,
  });

  @override
  State<DateRangeFilter> createState() => _DateRangeFilterState();
}

class _DateRangeFilterState extends State<DateRangeFilter> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bộ lọc thời gian',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  'Từ ngày',
                  _startDate,
                  (date) {
                    setState(() {
                      _startDate = date;
                    });
                    widget.onDateRangeChanged(_startDate, _endDate);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  'Đến ngày',
                  _endDate,
                  (date) {
                    setState(() {
                      _endDate = date;
                    });
                    widget.onDateRangeChanged(_startDate, _endDate);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickButton(
                icon: Icons.today,
                label: 'Hôm nay',
                onPressed: _selectToday,
              ),
              _quickButton(
                icon: Icons.date_range,
                label: 'Tuần này',
                onPressed: _selectThisWeek,
              ),
              _quickButton(
                icon: Icons.calendar_month,
                label: 'Tháng này',
                onPressed: _selectThisMonth,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickButton(
                icon: Icons.keyboard_arrow_left,
                label: 'Tháng trước',
                onPressed: _selectLastMonth,
              ),
              _quickButton(
                icon: Icons.clear,
                label: 'Xóa bộ lọc',
                onPressed: _clearDates,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, Function(DateTime?) onChanged) {
    return InkWell(
      onTap: () => _selectDate(onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null ? _formatDate(date) : 'Chọn ngày',
              style: TextStyle(
                fontSize: 14,
                color: date != null ? Colors.black : Colors.grey,
                fontWeight: date != null ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: const TextStyle(fontSize: 12),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
        shape: const StadiumBorder(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Future<void> _selectDate(Function(DateTime?) onChanged) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      onChanged(date);
    }
  }

  void _selectToday() {
    final today = DateTime.now();
    setState(() {
      _startDate = today;
      _endDate = today;
    });
    widget.onDateRangeChanged(_startDate, _endDate);
  }

  void _selectThisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    setState(() {
      _startDate = startOfWeek;
      _endDate = now;
    });
    widget.onDateRangeChanged(_startDate, _endDate);
  }

  void _selectThisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    setState(() {
      _startDate = startOfMonth;
      _endDate = now;
    });
    widget.onDateRangeChanged(_startDate, _endDate);
  }

  void _selectLastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = DateTime(now.year, now.month, 0);
    setState(() {
      _startDate = lastMonth;
      _endDate = endOfLastMonth;
    });
    widget.onDateRangeChanged(_startDate, _endDate);
  }

  void _clearDates() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    widget.onDateRangeChanged(_startDate, _endDate);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
