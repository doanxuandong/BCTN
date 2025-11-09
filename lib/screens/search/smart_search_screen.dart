import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/smart_search_question.dart';
import '../../services/search/smart_search_service.dart';
import '../../services/location/location_service.dart';
import '../../constants/vn_provinces.dart' as vn_provinces_const;
import 'search_results_screen.dart';

class SmartSearchScreen extends StatefulWidget {
  const SmartSearchScreen({super.key});

  @override
  State<SmartSearchScreen> createState() => _SmartSearchScreenState();
}

class _SmartSearchScreenState extends State<SmartSearchScreen> {
  UserAccountType _selectedType = UserAccountType.designer;
  List<SmartSearchQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  Map<String, dynamic> _answers = {};
  bool _isLoading = false;
  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _getUserLocation();
  }

  void _loadQuestions() {
    setState(() {
      _questions = SmartSearchService.getQuestions(_selectedType);
    });
  }

  Future<void> _getUserLocation() async {
    final position = await LocationService.getCurrentLocationQuick();
    if (position != null && LocationService.isValidLocation(
        position.latitude, position.longitude)) {
      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildTypeSelector(),
        _buildProgressIndicator(),
        Expanded(
          child: _buildQuestionCard(),
        ),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypeChip(
              UserAccountType.designer,
              'Nhà thiết kế',
              'Nhà thiết kế',
              Icons.design_services,
            ),
            const SizedBox(width: 8),
            _buildTypeChip(
              UserAccountType.contractor,
              'Chủ thầu',
              'Chủ thầu',
              Icons.engineering,
            ),
            const SizedBox(width: 8),
            _buildTypeChip(
              UserAccountType.store,
              'VLXD',
              'Cửa hàng VLXD',
              Icons.storefront,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(UserAccountType type, String shortLabel, String fullLabel, IconData icon) {
    final isSelected = _selectedType == type;
    return Tooltip(
      message: fullLabel,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            _currentQuestionIndex = 0;
            _answers.clear();
            _loadQuestions();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[600] : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[700]),
              const SizedBox(width: 4),
              Text(
                shortLabel,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Câu hỏi ${_currentQuestionIndex + 1}/${_questions.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${((_currentQuestionIndex + 1) / _questions.length * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    if (_currentQuestionIndex >= _questions.length) {
      return _buildSummaryCard();
    }

    final question = _questions[_currentQuestionIndex];
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.help_outline, color: Colors.blue[600]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question.question,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (question.hint != null) ...[
              const SizedBox(height: 8),
              Text(
                question.hint!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Expanded(
              child: _buildAnswerWidget(question),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerWidget(SmartSearchQuestion question) {
    switch (question.type) {
      case QuestionType.singleChoice:
        return _buildSingleChoiceAnswer(question);
      case QuestionType.multipleChoice:
        return _buildMultipleChoiceAnswer(question);
      case QuestionType.slider:
        return _buildSliderAnswer(question);
      case QuestionType.location:
        return _buildLocationAnswer(question);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSingleChoiceAnswer(SmartSearchQuestion question) {
    final currentAnswer = _answers[question.id];
    return ListView.builder(
      itemCount: question.options.length,
      itemBuilder: (context, index) {
        final option = question.options[index];
        final isSelected = currentAnswer != null &&
            currentAnswer is Map &&
            currentAnswer['id'] == option.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isSelected ? 4 : 1,
          color: isSelected ? Colors.blue[50] : Colors.white,
          child: ListTile(
            title: Text(option.label),
            leading: Radio<Map<String, dynamic>>(
              value: option.criteria,
              groupValue: isSelected ? option.criteria : null,
              onChanged: (value) {
                setState(() {
                  _answers[question.id] = {...option.criteria, 'id': option.id};
                });
              },
            ),
            onTap: () {
              setState(() {
                _answers[question.id] = {...option.criteria, 'id': option.id};
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildMultipleChoiceAnswer(SmartSearchQuestion question) {
    final currentAnswers = _answers[question.id] as List? ?? [];
    return ListView.builder(
      itemCount: question.options.length,
      itemBuilder: (context, index) {
        final option = question.options[index];
        final isSelected = currentAnswers.any((a) =>
            a is Map && a['id'] == option.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isSelected ? 4 : 1,
          color: isSelected ? Colors.blue[50] : Colors.white,
          child: CheckboxListTile(
            title: Text(option.label),
            value: isSelected,
            onChanged: (value) {
              setState(() {
                final answers = List<Map<String, dynamic>>.from(currentAnswers);
                if (value == true) {
                  answers.add({...option.criteria, 'id': option.id});
                } else {
                  answers.removeWhere((a) => a['id'] == option.id);
                }
                _answers[question.id] = answers;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildSliderAnswer(SmartSearchQuestion question) {
    double minValue = 5;
    double maxValue = 200;
    double currentValue = (_answers[question.id] as double?) ?? 50;

    // Adjust range based on question
    if (question.id.contains('contractor')) {
      minValue = 100;
      maxValue = 10000;
      currentValue = (_answers[question.id] as double?) ?? 1000;
    } else if (question.id.contains('store')) {
      minValue = 10;
      maxValue = 1000;
      currentValue = (_answers[question.id] as double?) ?? 100;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${currentValue.toInt()} triệu VNĐ',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 24),
        Slider(
          value: currentValue,
          min: minValue,
          max: maxValue,
          divisions: 100,
          label: '${currentValue.toInt()} triệu',
          onChanged: (value) {
            setState(() {
              _answers[question.id] = value;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${minValue.toInt()} triệu'),
            Text('${maxValue.toInt()} triệu'),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationAnswer(SmartSearchQuestion question) {
    String? selectedProvince = _answers[question.id] as String?;

    return ListView.builder(
      itemCount: vn_provinces_const.vnProvinces.length,
      itemBuilder: (context, index) {
        final provinceName = vn_provinces_const.vnProvinces[index];
        final isSelected = selectedProvince == provinceName;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: isSelected ? 4 : 1,
          color: isSelected ? Colors.blue[50] : Colors.white,
          child: ListTile(
            title: Text(provinceName),
            leading: Radio<String>(
              value: provinceName,
              groupValue: selectedProvince,
              onChanged: (value) {
                setState(() {
                  _answers[question.id] = value;
                });
              },
            ),
            onTap: () {
              setState(() {
                _answers[question.id] = provinceName;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green[600]),
          const SizedBox(height: 16),
          const Text(
            'Hoàn thành!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn đã trả lời ${_questions.length} câu hỏi',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _performSearch,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(_isLoading ? 'Đang tìm kiếm...' : 'Tìm kiếm ngay'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentQuestionIndex--;
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          if (_currentQuestionIndex > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _canGoNext() ? _goToNextQuestion : null,
              icon: const Icon(Icons.arrow_forward),
              label: Text(_currentQuestionIndex < _questions.length - 1
                  ? 'Tiếp theo'
                  : 'Xem tóm tắt'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canGoNext() {
    if (_currentQuestionIndex >= _questions.length) return false;
    final question = _questions[_currentQuestionIndex];
    if (question.isRequired) {
      return _answers.containsKey(question.id) && _answers[question.id] != null;
    }
    return true; // Optional questions can be skipped
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      // Show summary
      setState(() {
        _currentQuestionIndex = _questions.length;
      });
    }
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await SmartSearchService.searchAndScore(
        type: _selectedType,
        answers: _answers,
        userLat: _userLat,
        userLng: _userLng,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsScreen(
            smartSearchResults: results,
            searchAnswers: _answers,
            accountType: _selectedType,
            isSmartSearch: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tìm kiếm: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

