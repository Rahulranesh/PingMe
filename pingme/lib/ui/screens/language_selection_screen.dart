import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/language_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neumorphic_container.dart';
import '../../widgets/translated_text.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    final languageService = context.read<LanguageService>();
    _selectedLanguage = languageService.currentLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<LanguageService>(
          builder: (context, languageService, _) => TranslatedText(
            'language',
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<LanguageService>(
        builder: (context, languageService, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeumorphicContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.language,
                            color: AppTheme.primaryColor,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          TranslatedText(
                            'select_language',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TranslatedText(
                        'choose_language',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
                
                const SizedBox(height: 20),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: languageService.supportedLanguages.length,
                    itemBuilder: (context, index) {
                      final languageCode = languageService.supportedLanguages.keys.elementAt(index);
                      final languageName = languageService.supportedLanguages[languageCode]!;
                      final flag = languageService.getLanguageFlag(languageCode);
                      final isSelected = _selectedLanguage == languageCode;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: NeumorphicContainer(
                          child: ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected 
                                    ? AppTheme.primaryColor.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                              ),
                              child: Center(
                                child: Text(
                                  flag,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            title: Text(
                              languageName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppTheme.primaryColor : null,
                              ),
                            ),
                            subtitle: Text(
                              languageCode.toUpperCase(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: AppTheme.primaryColor,
                                    size: 24,
                                  )
                                : Icon(
                                    Icons.radio_button_unchecked,
                                    color: Colors.grey.withOpacity(0.5),
                                    size: 24,
                                  ),
                            onTap: () => _selectLanguage(languageCode, languageService),
                          ),
                        ).animate().fadeIn(delay: (index * 50).ms, duration: 300.ms).slideX(begin: 0.2),
                      );
                    },
                  ),
                ),
                
                // Apply button
                NeumorphicContainer(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedLanguage != languageService.currentLanguage
                          ? () => _applyLanguage(languageService)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          TranslatedText(
                            'apply_language',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
              ],
            ),
          );
        },
      ),
    );
  }

  void _selectLanguage(String languageCode, LanguageService languageService) {
    setState(() {
      _selectedLanguage = languageCode;
    });
  }

  void _applyLanguage(LanguageService languageService) async {
    if (_selectedLanguage != null) {
      await languageService.setLanguage(_selectedLanguage!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Language changed to ${languageService.getLanguageName(_selectedLanguage!)}',
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Pop back to settings
        Navigator.pop(context);
      }
    }
  }
}
