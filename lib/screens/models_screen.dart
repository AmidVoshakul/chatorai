import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gen_ui_chat_ai/providers/theme_provider.dart';
import 'package:gen_ui_chat_ai/services/openrouter_service.dart';
import 'package:gen_ui_chat_ai/themes/app_theme.dart';
import 'package:gen_ui_chat_ai/themes/app_theme.dart' show UbuntuColors;
import 'package:gen_ui_chat_ai/utils/snackbar_utils.dart';

class ModelsScreen extends StatefulWidget {
  final Function(String)? onModelSelected;
  final String? currentModel;

  const ModelsScreen({
    Key? key,
    this.onModelSelected,
    this.currentModel,
  }) : super(key: key);

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  late OpenRouterService _openRouterService;
  late ThemeProvider _themeProvider;
  List<OpenRouterModel> _models = [];
  List<OpenRouterModel> _filteredModels = [];
  bool _isLoading = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
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

  // ==============================================
  // Search functionality
  // ==============================================

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

  // ==============================================
  // Model selection
  // ==============================================

  void _selectModel(OpenRouterModel model) {
    final String currentLanguage = _themeProvider.selectedLanguage;
    String getLocalizedText(String key) {
      if (currentLanguage == 'en') {
        return {
          'modelSelected': 'Model "${model.name}" selected for chat',
        }[key] ?? key;
      } else {
        return {
          'modelSelected': 'Модель "${model.name}" выбрана для общения',
        }[key] ?? key;
      }
    }
    
    // Call the callback if provided
    if (widget.onModelSelected != null) {
      widget.onModelSelected!(model.id);
    }
    
    // Show success snackbar
    SnackbarUtils.showSuccessSnackBar(
      context: context,
      message: getLocalizedText('modelSelected'),
      icon: Icons.check_circle,
    );
    
    // Navigate back to chat screen with selected model
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pop(model);
    });
  }

  // ==============================================
  // Data loading
  // ==============================================

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
        final String currentLanguage = _themeProvider.selectedLanguage;
        String getLocalizedText(String key) {
          if (currentLanguage == 'en') {
            return {
              'errorLoadingModels': 'Error loading models: $e',
            }[key] ?? key;
          } else {
            return {
              'errorLoadingModels': 'Ошибка загрузки моделей: $e',
            }[key] ?? key;
          }
        }
        
        SnackbarUtils.showWarningSnackBar(
          context: context,
          message: getLocalizedText('errorLoadingModels'),
          icon: Icons.warning,
          duration: const Duration(seconds: 3),
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
        title: Text(
          _themeProvider.selectedLanguage == 'en' ? 'Models' : 'Модели',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
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
                hintText: _themeProvider.selectedLanguage == 'en' ? 'Search models...' : 'Поиск моделей...',
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

  // ==============================================
  // UI Components
  // ==============================================

  Widget _buildModelCard(OpenRouterModel model) {
    final isSelected = widget.currentModel == model.id;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      elevation: 2,
      color: isSelected 
          ? Theme.of(context).cardColor
          : Theme.of(context).cardColor,
      shape: isSelected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: Colors.green,
                width: 2.0,
              ),
            )
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleMedium!.color,
                          ),
                          maxLines: 3,
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
                    tooltip: _themeProvider.selectedLanguage == 'en' ? 'Details' : 'Подробнее',
                  ),
                ],
              ),
const SizedBox(height: 12),
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? UbuntuColors.darkBorderColor 
                    : UbuntuColors.lightBorderColor,
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
                      '${_themeProvider.selectedLanguage == 'en' ? 'Context' : 'Контекст'}: ${model.formattedContextLength}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodySmall!.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildModelFeatures(model),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelFeatures(OpenRouterModel model) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        // Free/Paid indicator
        Chip(
          label: Text(model.isFree 
              ? (_themeProvider.selectedLanguage == 'en' ? 'Free' : 'Бесплатно')
              : (_themeProvider.selectedLanguage == 'en' ? 'Paid' : 'Платно')),
          backgroundColor: model.isFree 
              ? Colors.green.withValues(alpha: 0.15)
              : Colors.orange.withValues(alpha: 0.15),
          side: BorderSide(
            color: model.isFree 
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.orange.withValues(alpha: 0.3),
            width: 1.5,
          ),
          labelStyle: TextStyle(
            color: model.isFree ? Colors.green : Colors.orange,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          avatar: Icon(
            model.isFree ? Icons.attach_money : Icons.payment,
            size: 14,
            color: model.isFree ? Colors.green : Colors.orange,
          ),
        ),
        
        // Reasoning capability
        if (model.supportsReasoning)
          Chip(
            label: Text(_themeProvider.selectedLanguage == 'en' ? 'Reasoning' : 'Рассуждения'),
            backgroundColor: Colors.blue.withValues(alpha: 0.15),
            side: BorderSide(color: Colors.blue.withValues(alpha: 0.3), width: 1.5),
            labelStyle: const TextStyle(
              color: Colors.blue,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            avatar: const Icon(Icons.psychology, size: 14, color: Colors.blue),
          ),
        
        // Multimodal capability
        if (model.supportsMultimodal)
          Chip(
            label: Text(_themeProvider.selectedLanguage == 'en' ? 'Multimodal' : 'Мультимодальность'),
            backgroundColor: Colors.purple.withValues(alpha: 0.15),
            side: BorderSide(color: Colors.purple.withValues(alpha: 0.3), width: 1.5),
            labelStyle: const TextStyle(
              color: Colors.purple,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            avatar: const Icon(Icons.view_in_ar, size: 14, color: Colors.purple),
          ),
        
        // Vision capability
        if (model.capabilities.vision)
          Chip(
            label: Text(_themeProvider.selectedLanguage == 'en' ? 'Vision' : 'Видение'),
            backgroundColor: Colors.deepOrange.withValues(alpha: 0.15),
            side: BorderSide(color: Colors.deepOrange.withValues(alpha: 0.3), width: 1.5),
            labelStyle: const TextStyle(
              color: Colors.deepOrange,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            avatar: const Icon(Icons.visibility, size: 14, color: Colors.deepOrange),
          ),
        
        // Tools capability
        if (model.capabilities.tools)
          Chip(
            label: Text(_themeProvider.selectedLanguage == 'en' ? 'Tools' : 'Инструменты'),
            backgroundColor: Colors.teal.withValues(alpha: 0.15),
            side: BorderSide(color: Colors.teal.withValues(alpha: 0.3), width: 1.5),
            labelStyle: const TextStyle(
              color: Colors.teal,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            avatar: const Icon(Icons.build, size: 14, color: Colors.teal),
          ),
        
        // Always show availability
        Chip(
          label: Text(_themeProvider.selectedLanguage == 'en' ? 'Available' : 'Доступна'),
          backgroundColor: Colors.green.withValues(alpha: 0.15),
          side: BorderSide(color: Colors.green.withValues(alpha: 0.3), width: 1.5),
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
    // ==============================================
    // Show model details
    // ==============================================

    /// Builds a detail row with icon, label, and value
    Widget _buildDetailRow(String label, String value, IconData icon) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyMedium!.color,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall!.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    /// Builds a feature chip with label, color, and icon
    Widget _buildFeatureChip(String label, bool enabled, Color color, IconData icon) {
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        child: Chip(
          label: Text(label, style: TextStyle(color: enabled ? color : Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
          backgroundColor: enabled ? color.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
          side: BorderSide(
            color: enabled ? color.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.3),
            width: 1.5,
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          avatar: Icon(icon, size: 14, color: enabled ? color : Colors.grey[600]),
        ),
      );
    }

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
                  color: Theme.of(context).textTheme.titleLarge!.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                model.id,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall!.color,
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
                _themeProvider.selectedLanguage == 'en' ? 'Description' : 'Описание',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleMedium!.color,
                ),
              ),
              const SizedBox(height: 4),
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? UbuntuColors.darkBorderColor 
                    : UbuntuColors.lightBorderColor,
              ),
              const SizedBox(height: 8),
              Text(
                model.description,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Technical details
              Text(
                _themeProvider.selectedLanguage == 'en' ? 'Technical Details' : 'Технические характеристики',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleMedium!.color,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(_themeProvider.selectedLanguage == 'en' ? 'Provider' : 'Провайдер', model.provider!, Icons.account_circle),
              if (model.provider != null)
                _buildDetailRow(_themeProvider.selectedLanguage == 'en' ? 'Context' : 'Контекст', model.formattedContextLength, Icons.text_fields),

              _buildDetailRow(
                _themeProvider.selectedLanguage == 'en' ? 'Input tokens' : 'Ввод токенов',
                model.pricingPrompt != null
                    ? '\$${model.pricingPrompt}/M'
                    : (_themeProvider.selectedLanguage == 'en' ? 'Not available' : 'Недоступно'),
                Icons.attach_money,
              ),
              _buildDetailRow(
                _themeProvider.selectedLanguage == 'en' ? 'Output tokens' : 'Вывод токенов',
                model.pricingCompletion != null
                    ? '\$${model.pricingCompletion}/M'
                    : (_themeProvider.selectedLanguage == 'en' ? 'Not available' : 'Недоступно'),
                Icons.monetization_on,
              ),

              // Features section
              const SizedBox(height: 20),
              Text(
                _themeProvider.selectedLanguage == 'en' ? 'Features' : 'Возможности',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleMedium!.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _themeProvider.selectedLanguage == 'en'
                  ? 'Features are displayed based on actual model capabilities'
                  : 'Возможности отображаются на основе реальных характеристик модели',
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
                  _buildFeatureChip(
                    model.isFree 
                      ? (_themeProvider.selectedLanguage == 'en' ? 'Free' : 'Бесплатно')
                      : (_themeProvider.selectedLanguage == 'en' ? 'Paid' : 'Платно'),
                    true,
                    model.isFree ? Colors.green : Colors.orange,
                    model.isFree ? Icons.attach_money : Icons.payment,
                  ),
                  if (model.supportsReasoning)
                    _buildFeatureChip(_themeProvider.selectedLanguage == 'en' ? 'Reasoning' : 'Рассуждения', true, Colors.blue, Icons.psychology),
                  if (model.supportsMultimodal)
                    _buildFeatureChip(_themeProvider.selectedLanguage == 'en' ? 'Multimodal' : 'Мультимодальность', true, Colors.purple, Icons.view_in_ar),
                  if (model.capabilities.vision)
                    _buildFeatureChip(_themeProvider.selectedLanguage == 'en' ? 'Vision' : 'Видение', true, Colors.deepOrange, Icons.visibility),
                  if (model.capabilities.tools)
                    _buildFeatureChip(_themeProvider.selectedLanguage == 'en' ? 'Tools' : 'Инструменты', true, Colors.teal, Icons.build),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(_themeProvider.selectedLanguage == 'en' ? 'Close' : 'Закрыть'),
            ),
          ],
        );
      },
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
            color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            isEmptySearch 
              ? (_themeProvider.selectedLanguage == 'en' ? 'No models found' : 'Модели не найдены')
              : (_themeProvider.selectedLanguage == 'en' ? 'No available models' : 'Нет доступных моделей'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge!.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEmptySearch 
              ? (_themeProvider.selectedLanguage == 'en' ? 'Try a different search query' : 'Попробуйте изменить поисковый запрос')
              : (_themeProvider.selectedLanguage == 'en' ? 'Try refreshing or check your internet connection' : 'Попробуйте обновить или проверьте интернет-соединение'),
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
