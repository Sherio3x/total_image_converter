import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'services/ad_manager.dart';
import 'services/usage_manager.dart';
import 'services/image_converter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AdManager.initialize();
  runApp(const TotalImageConverterApp());
}

class TotalImageConverterApp extends StatelessWidget {
  const TotalImageConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Total Image Converter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ImageConverterHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ImageConverterHome extends StatefulWidget {
  const ImageConverterHome({super.key});

  @override
  State<ImageConverterHome> createState() => _ImageConverterHomeState();
}

class _ImageConverterHomeState extends State<ImageConverterHome> {
  List<File> _selectedImages = [];
  ImageFormat _selectedFormat = ImageFormat.jpg;
  double _quality = 0.9;
  bool _isConverting = false;
  bool _isBatchMode = false;
  int _remainingBatchUsage = 3;
  int _conversionProgress = 0;
  int _totalConversions = 0;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _updateRemainingUsage();
  }

  Future<void> _updateRemainingUsage() async {
    final remaining = await UsageManager.getRemainingBatchUsage();
    setState(() {
      _remainingBatchUsage = remaining;
    });
  }

  Future<void> _pickSingleImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImages = [File(image.path)];
          _isBatchMode = false;
        });
      }
    } catch (e) {
      _showSnackBar('خطأ في اختيار الصورة: $e');
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        // Limit to 5 images for batch conversion
        final limitedImages = images.take(5).map((xFile) => File(xFile.path)).toList();
        setState(() {
          _selectedImages = limitedImages;
          _isBatchMode = true;
        });
      }
    } catch (e) {
      _showSnackBar('خطأ في اختيار الصور: $e');
    }
  }

  Future<void> _convertImages() async {
    if (_selectedImages.isEmpty) {
      _showSnackBar('يرجى اختيار صورة أو صور أولاً');
      return;
    }

    // Check if batch conversion requires rewarded ad
    if (_isBatchMode && _selectedImages.length > 1) {
      final canUse = await UsageManager.canUseBatchConversion();
      if (!canUse) {
        _showSnackBar('لقد استنفدت استخدامات التحويل الدفعي لليوم (3 مرات)');
        return;
      }

      // Show rewarded ad for batch conversion
      if (!AdManager.isRewardedAdReady()) {
        _showSnackBar('الإعلان غير جاهز، يرجى المحاولة لاحقاً');
        return;
      }

      final rewardEarned = await AdManager.showRewardedAd();
      if (!rewardEarned) {
        _showSnackBar('يجب مشاهدة الإعلان كاملاً للحصول على التحويل الدفعي');
        return;
      }

      // Increment batch usage after successful ad view
      await UsageManager.incrementBatchUsage();
      await _updateRemainingUsage();
    }

    setState(() {
      _isConverting = true;
      _conversionProgress = 0;
      _totalConversions = _selectedImages.length;
    });

    try {
      List<String> convertedPaths;

      if (_selectedImages.length == 1) {
        // Single image conversion
        final convertedPath = await ImageConverter.convertSingleImage(
          sourceFile: _selectedImages.first,
          targetFormat: _selectedFormat,
          quality: _quality,
        );
        convertedPaths = convertedPath != null ? [convertedPath] : [];
      } else {
        // Batch conversion
        convertedPaths = await ImageConverter.convertMultipleImages(
          sourceFiles: _selectedImages,
          targetFormat: _selectedFormat,
          quality: _quality,
          onProgress: (current, total) {
            setState(() {
              _conversionProgress = current;
            });
          },
        );
      }

      if (convertedPaths.isNotEmpty) {
        final formatName = ImageConverter.formatNames[_selectedFormat]!;
        _showSnackBar(
          'تم تحويل ${convertedPaths.length} صورة إلى $formatName بنجاح!'
        );
        
        // Show interstitial ad after successful conversion (for single images)
        if (_selectedImages.length == 1) {
          AdManager.showInterstitialAd();
        }
      } else {
        _showSnackBar('فشل في تحويل الصور');
      }

    } catch (e) {
      _showSnackBar('خطأ في تحويل الصور: $e');
    } finally {
      setState(() {
        _isConverting = false;
        _conversionProgress = 0;
        _totalConversions = 0;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    AdManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Total Image Converter',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.image,
                      size: 64,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'محول الصور الشامل',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'حول صورك بين صيغ مختلفة بسهولة',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isBatchMode && _selectedImages.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'التحويل الدفعي متبقي: $_remainingBatchUsage مرات اليوم',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // Image selection section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'اختر الصور',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_selectedImages.isNotEmpty) ...[
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _selectedImages.length == 1
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImages.first,
                                fit: BoxFit.cover,
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 4,
                              ),
                              itemCount: _selectedImages.length,
                              itemBuilder: (context, index) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.file(
                                    _selectedImages[index],
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedImages.length == 1 
                          ? 'تم اختيار صورة واحدة'
                          : 'تم اختيار ${_selectedImages.length} صور',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickSingleImage,
                            icon: const Icon(Icons.photo),
                            label: const Text('صورة واحدة'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickMultipleImages,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('عدة صور'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Conversion settings section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'إعدادات التحويل',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Format selection
                    const Text(
                      'الصيغة المطلوبة:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ImageFormat>(
                      value: _selectedFormat,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: ImageConverter.getSupportedOutputFormats().map((ImageFormat format) {
                        return DropdownMenuItem<ImageFormat>(
                          value: format,
                          child: Text(ImageConverter.formatNames[format]!),
                        );
                      }).toList(),
                      onChanged: (ImageFormat? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedFormat = newValue;
                          });
                        }
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Quality slider (only for JPG and WebP)
                    if (ImageConverter.supportsQuality(_selectedFormat)) ...[
                      Text(
                        'الجودة: ${(_quality * 100).round()}%',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Slider(
                        value: _quality,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        onChanged: (double value) {
                          setState(() {
                            _quality = value;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Progress indicator
            if (_isConverting && _totalConversions > 1) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'جاري التحويل: $_conversionProgress من $_totalConversions',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _totalConversions > 0 ? _conversionProgress / _totalConversions : 0,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Convert button
            ElevatedButton.icon(
              onPressed: _isConverting ? null : _convertImages,
              icon: _isConverting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.transform),
              label: Text(_isConverting ? 'جاري التحويل...' : 'تحويل الصور'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),

            // Batch conversion info
            if (_isBatchMode && _selectedImages.length > 1) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700]),
                    const SizedBox(height: 8),
                    Text(
                      'التحويل الدفعي يتطلب مشاهدة إعلان قصير',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'متاح 3 مرات يوميًا في النسخة المجانية',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

