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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _openRouterService = OpenRouterService();
    _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final models = await _openRouterService.getAvailableModels();
      setState(() {
        _models = models;
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _models.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _models.length,
                  itemBuilder: (context, index) {
                    final model = _models[index];
                    return _buildModelCard(model);
                  },
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
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        model.id,
                        style: TextStyle(
                          color: Colors.grey[600],
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
                color: Colors.grey[700],
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
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
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
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.model_training,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Нет доступных моделей',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Попробуйте обновить или проверьте интернет-соединение',
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}