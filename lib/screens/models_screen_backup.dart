import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/services/openrouter_service.dart';

class ModelsScreen extends StatefulWidget {
  const ModelsScreen({Key? key}) : super(key: key);

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  late OpenRouterService _openRouterService;
  List<OpenRouterModel> _models = [];
  List<OpenRouterModel> _filteredModels = [];
  bool _isLoading = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _openRouterService = OpenRouterService();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
    _loadModels();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isEmpty) {
      setState(() {
        _filteredModels = _models;
      });
    } else {
      setState(() {
        _filteredModels = _models.where((model) {
          return model.name.toLowerCase().contains(searchQuery) ||
                 model.id.toLowerCase().contains(searchQuery) ||
                 model.description.toLowerCase().contains(searchQuery) ||
                 (model.provider?.toLowerCase().contains(searchQuery) ?? false);
        }).toList();
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filteredModels = _models;
    });
  }

  void _selectModel(OpenRouterModel model) {
    // Show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Модель "${model.name}" выбрана для общения'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Navigate back to chat screen with selected model
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pop(model);
    });
  }

  Future<void> _loadModels() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final models = await _openRouterService.getAvailableModels();
      setState(() {
        _models = models;
        _filteredModels = models;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки моделей: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Доступные модели'),
        backgroundColor: Theme.of(context).canvasColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск моделей...',
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700],
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700],
                        ),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[700]! 
                        : Colors.grey[400]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[700]! 
                        : Colors.grey[400]!,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark 
                    ? Theme.of(context).cardColor 
                    : Colors.white,
                isDense: true,
              ),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge!.color,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: Theme.of(context).primaryColor,
              textInputAction: TextInputAction.search,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredModels.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _filteredModels.length,
                        itemBuilder: (context, index) {
                          final model = _filteredModels[index];
                          return _buildModelCard(model);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadModels,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildModelCard(OpenRouterModel model) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          _selectModel(model);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleMedium!.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          model.id,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall!.color,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Info button
                  IconButton(
                    icon: const Icon(
                      Icons.info,
                      color: Colors.blueAccent,
                      size: 24,
                    ),
                    onPressed: () {
                      _showModelDetailsDialog(model);
                    },
                    tooltip: 'Подробнее',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
              model.description,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium!.color,
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Контекст: ${model.formattedContextLength}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodySmall!.color,
                    ),
                  ),
                ),
                if (model.provider != null)
                  Chip(
                    label: Text(model.provider!),
                    backgroundColor: Colors.indigo[50],
                    labelStyle: const TextStyle(fontSize: 10),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _buildModelFeatures(model),
          ],
        ),
      ),
    );
  }

  Widget _buildModelFeatures(OpenRouterModel model) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (model.isFree)
          Chip(
            label: const Text('Бесплатно'),
            backgroundColor: Colors.green.withOpacity(0.15),
            side: BorderSide(color: Colors.green.withOpacity(0.3), width: 1.5),
            labelStyle: const TextStyle(
              color: Colors.green,
              fontSize: 11, 
              fontWeight: FontWeight.w500,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            avatar: const Icon(Icons.attach_money, size: 14, color: Colors.green),
          ),
        if (model.supportsReasoning)
          Chip(
            label: const Text('Рассуждения'),
            backgroundColor: Colors.blue.withOpacity(0.15),
            side: BorderSide(color: Colors.blue.withOpacity(0.3), width: 1.5),
            labelStyle: const TextStyle(
              color: Colors.blue,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            avatar: const Icon(Icons.psychology, size: 14, color: Colors.blue),
          ),
        if (model.supportsMultimodal)
          Chip(
            label: const Text('Мультимодальность'),
            backgroundColor: Colors.purple.withOpacity(0.15),
            side: BorderSide(color: Colors.purple.withOpacity(0.3), width: 1.5),
            labelStyle: const TextStyle(
              color: Colors.purple,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            avatar: const Icon(Icons.view_in_ar, size: 14, color: Colors.purple),
          ),
        // Always show availability
        Chip(
          label: const Text('Доступна'),
          backgroundColor: Colors.green.withOpacity(0.15),
          side: BorderSide(color: Colors.green.withOpacity(0.3), width: 1.5),
          labelStyle: const TextStyle(
            color: Colors.green,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          avatar: const Icon(Icons.check_circle, size: 14, color: Colors.green),
        ),
      ],
    );
  }

  void _showModelDetailsDialog(OpenRouterModel model) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          scrollable: true,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                model.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                model.id,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description section
              Text(
                'Описание:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                model.description,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Technical details
              Text(
                'Технические характеристики:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Контекст', model.formattedContextLength, Icons.text_fields),
              if (model.provider != null)
                _buildDetailRow('Провайдер', model.provider!, Icons.account_circle),
              
              // Features section
              const SizedBox(height: 20),
              Text(
                'Возможности:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleMedium!.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Каждая возможность отображается цветным значком',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall!.color,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFeatureChip('Бесплатно', true, Colors.green, Icons.attach_money),
                  _buildFeatureChip('Рассуждения', true, Colors.blue, Icons.psychology),
                  _buildFeatureChip('Мультимодальность', true, Colors.purple, Icons.view_in_ar),
                  _buildFeatureChip('Видение', true, Colors.deepOrange, Icons.visibility),
                  _buildFeatureChip('Инструменты', true, Colors.teal, Icons.build),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.blueAccent : Colors.blueAccent),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, bool enabled, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Chip(
        label: Text(label, style: TextStyle(color: enabled ? color : Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
        backgroundColor: enabled ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
        side: BorderSide(
          color: enabled ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          width: 1.5,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        avatar: Icon(icon, size: 14, color: enabled ? color : Colors.grey[600]),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isEmptySearch = _searchController.text.isNotEmpty && _filteredModels.isEmpty;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isEmptySearch ? Icons.search_off : Icons.model_training,
            size: 80,
            color: Theme.of(context).primaryColor.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            isEmptySearch ? 'Модели не найдены' : 'Нет доступных моделей',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge!.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEmptySearch 
              ? 'Попробуйте изменить поисковый запрос'
              : 'Попробуйте обновить или проверьте интернет-соединение',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium!.color,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}