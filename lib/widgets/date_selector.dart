import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';

class DateSelector extends StatefulWidget {
  const DateSelector({super.key});

  @override
  State<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends State<DateSelector> {
  final ScrollController _scrollController = ScrollController();
  int _leftHiddenTasks = 0;
  int _rightHiddenTasks = 0;
  DateTime? _nearestLeftDate;
  DateTime? _nearestRightDate;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateHiddenTasks);
    // Initial check after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateHiddenTasks());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateHiddenTasks);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateHiddenTasks() {
    if (!mounted) return;
    
    final provider = Provider.of<TodoProvider>(context, listen: false);
    final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    // Assuming item width approx 70 (60 width + 10 margin)
    // We can be more precise if we knew exact render box, but approx is fine for "out of view"
    const itemExtent = 70.0;
    final viewportWidth = _scrollController.hasClients 
        ? _scrollController.position.viewportDimension 
        : MediaQuery.of(context).size.width; 
        
    final firstVisibleIndex = (offset / itemExtent).floor();
    final lastVisibleIndex = ((offset + viewportWidth) / itemExtent).ceil();

    int leftCount = 0;
    DateTime? nearestLeft;
    int rightCount = 0;
    DateTime? nearestRight;

    // We have 30 days total in the list
    // indices 0 to 29
    // Index 0 is 15 days ago.
    
    // Check left hidden
    for (int i = 0; i < firstVisibleIndex; i++) {
      if (i >= 0 && i < 30) {
        final date = DateTime.now().subtract(const Duration(days: 15)).add(Duration(days: i));
        final count = provider.getTaskCountForDate(date);
        if (count > 0) {
          leftCount += count;
          nearestLeft = date; // Last one found (closest to view) is actually nearest?
          // No, loop 0->firstVisible. Nearest to View is the one with highest index.
          // So we should just update nearestLeft every time we find one.
        }
      }
    }

    // Check right hidden
    for (int i = lastVisibleIndex + 1; i < 30; i++) {
       if (i >= 0 && i < 30) {
        final date = DateTime.now().subtract(const Duration(days: 15)).add(Duration(days: i));
        final count = provider.getTaskCountForDate(date);
        if (count > 0) {
          rightCount += count;
          // Nearest to View is the one with lowest index.
          if (nearestRight == null) nearestRight = date;
        }
      }
    }

    if (leftCount != _leftHiddenTasks || rightCount != _rightHiddenTasks) {
       setState(() {
         _leftHiddenTasks = leftCount;
         _rightHiddenTasks = rightCount;
         _nearestLeftDate = nearestLeft;
         _nearestRightDate = nearestRight;
       });
    }
  }

  void _scrollToDate(DateTime date) {
    // Find index of date
    final start = DateTime.now().subtract(const Duration(days: 15));
    final diff = date.difference(start).inDays;
    if (diff >= 0 && diff < 30) {
      _scrollController.animateTo(
        diff * 70.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to provider to update counts if tasks change
    final todoProvider = Provider.of<TodoProvider>(context);
    // We should re-calc hidden tasks when provider updates
    // Use addPostFrameCallback to avoid initState/build conflict or just call it?
    // Provide is stable, but we need to re-run logic.
    // Let's rely on listener or just rebuild.
    // The build method triggers, but _updateHiddenTasks relies on scroll position which hasn't changed.
    // But data has changed. So we should re-run logic.
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateHiddenTasks());
    
    final selectedDate = todoProvider.selectedDate;

    return Container(
      height: 185, // Increased height for arrows/header
      padding: const EdgeInsets.only(top: 20, bottom: 35),
      decoration: const BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(selectedDate),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null && picked != selectedDate) {
                      todoProvider.setDate(picked);
                      _scrollToDate(picked);
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: 30, // Show previous 15 and next 14 days
                  itemBuilder: (context, index) {
                    final date = DateTime.now().subtract(const Duration(days: 15)).add(Duration(days: index));
                    final isSelected = date.year == selectedDate.year &&
                        date.month == selectedDate.month &&
                        date.day == selectedDate.day;
                        
                    final status = todoProvider.getTaskStatusForDate(date);
                    // 0: No tasks, 1: Uncompleted, 2: All Completed
                    
                    Color bgColor;
                    Color textColor;
                    Color dayColor;

                    if (isSelected) {
                        // If selected, keep it distinct?
                        // Or merge status logic? User says:
                        // "Each date with >0 uncompleted ... white"
                        // "Days with all completed ... green"
                        // What if selected?
                        // Let's use a border or different shade for selected.
                        // Or stick to the requirement colors and use a Border Highlight for selection.
                        if (status == 1) {
                           bgColor = Colors.white;
                           textColor = Colors.blue; 
                           dayColor = Colors.blue;
                        } else if (status == 2) {
                           bgColor = Colors.green;
                           textColor = Colors.white;
                           dayColor = Colors.white70;
                        } else {
                           bgColor = Colors.white; // Default selection
                           textColor = Colors.blue;
                           dayColor = Colors.grey;
                        }
                    } else {
                        if (status == 1) {
                           bgColor = Colors.white;
                           textColor = Colors.blue;
                           dayColor = Colors.grey;
                        } else if (status == 2) {
                           bgColor = Colors.green;
                           textColor = Colors.white;
                           dayColor = Colors.white70;
                        } else {
                           bgColor = Colors.blueGrey[100]!; // "grayish blue"
                           textColor = Colors.blueGrey[900]!;
                           dayColor = Colors.blueGrey[700]!;
                        }
                    }

                    return GestureDetector(
                      onTap: () {
                        todoProvider.setDate(date);
                      },
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(15),
                          border: isSelected ? Border.all(color: Colors.yellow, width: 2) : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('E').format(date),
                              style: TextStyle(
                                color: dayColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('d').format(date),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (_leftHiddenTasks > 0)
                  Positioned(
                    left: 0,
                    child: GestureDetector(
                      onTap: () {
                        if (_nearestLeftDate != null) _scrollToDate(_nearestLeftDate!);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.black26, 
                        // User said "white arrow with the number of tasks out of view behind the arrow"
                        // Maybe standard Row: Arrow < [Count]
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                            Text(
                              '$_leftHiddenTasks',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_rightHiddenTasks > 0)
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                         if (_nearestRightDate != null) _scrollToDate(_nearestRightDate!);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.black26,
                        child: Row(
                          children: [
                            Text(
                              '$_rightHiddenTasks',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
