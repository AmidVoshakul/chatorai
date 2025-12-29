import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/utils/image_utils.dart';

void main() {
  group('ImageUtils getMimeType Tests', () {
    // Test 1: Image file types
    test('returns correct MIME type for image files', () {
      expect(ImageUtils.getMimeType('photo.jpg'), 'image/jpeg');
      expect(ImageUtils.getMimeType('photo.jpeg'), 'image/jpeg');
      expect(ImageUtils.getMimeType('image.png'), 'image/png');
      expect(ImageUtils.getMimeType('animation.gif'), 'image/gif');
      expect(ImageUtils.getMimeType('picture.webp'), 'image/webp');
      expect(ImageUtils.getMimeType('icon.svg'), 'image/svg+xml');
    });

    // Test 2: Text file types
    test('returns correct MIME type for text files', () {
      expect(ImageUtils.getMimeType('readme.txt'), 'text/plain');
      expect(ImageUtils.getMimeType('notes.md'), 'text/markdown');
      expect(ImageUtils.getMimeType('data.csv'), 'text/csv');
      expect(ImageUtils.getMimeType('page.html'), 'text/html');
      expect(ImageUtils.getMimeType('config.xml'), 'text/xml');
      expect(ImageUtils.getMimeType('data.json'), 'application/json');
      expect(ImageUtils.getMimeType('config.yaml'), 'application/yaml');
    });

    // Test 3: Document file types
    test('returns correct MIME type for document files', () {
      expect(ImageUtils.getMimeType('document.pdf'), 'application/pdf');
      expect(ImageUtils.getMimeType('file.doc'), 'application/msword');
      expect(ImageUtils.getMimeType('file.docx'), 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
      expect(ImageUtils.getMimeType('data.xls'), 'application/vnd.ms-excel');
      expect(ImageUtils.getMimeType('data.xlsx'), 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    });

    // Test 4: Archive file types
    test('returns correct MIME type for archive files', () {
      expect(ImageUtils.getMimeType('archive.zip'), 'application/zip');
      expect(ImageUtils.getMimeType('archive.rar'), 'application/x-rar-compressed');
      expect(ImageUtils.getMimeType('archive.7z'), 'application/x-7z-compressed');
      expect(ImageUtils.getMimeType('backup.tar'), 'application/x-tar');
      expect(ImageUtils.getMimeType('compressed.gz'), 'application/gzip');
    });

    // Test 5: Code file types
    test('returns correct MIME type for code files', () {
      expect(ImageUtils.getMimeType('main.dart'), 'text/dart');
      expect(ImageUtils.getMimeType('script.js'), 'text/javascript');
      expect(ImageUtils.getMimeType('types.ts'), 'text/typescript');
      expect(ImageUtils.getMimeType('app.py'), 'text/x-python');
      expect(ImageUtils.getMimeType('Program.java'), 'text/x-java');
      expect(ImageUtils.getMimeType('code.cpp'), 'text/x-c');
      expect(ImageUtils.getMimeType('program.cs'), 'text/x-csharp');
      expect(ImageUtils.getMimeType('main.go'), 'text/x-go');
      expect(ImageUtils.getMimeType('lib.rs'), 'text/x-rust');
      expect(ImageUtils.getMimeType('index.php'), 'text/x-php');
      expect(ImageUtils.getMimeType('app.rb'), 'text/x-ruby');
    });

    // Test 6: Audio file types
    test('returns correct MIME type for audio files', () {
      expect(ImageUtils.getMimeType('music.mp3'), 'audio/mpeg');
      expect(ImageUtils.getMimeType('sound.wav'), 'audio/wav');
      expect(ImageUtils.getMimeType('audio.ogg'), 'audio/ogg');
      expect(ImageUtils.getMimeType('song.m4a'), 'audio/mp4');
    });

    // Test 7: Video file types
    test('returns correct MIME type for video files', () {
      expect(ImageUtils.getMimeType('video.mp4'), 'video/mp4');
      expect(ImageUtils.getMimeType('clip.avi'), 'video/x-msvideo');
      expect(ImageUtils.getMimeType('movie.mov'), 'video/quicktime');
      expect(ImageUtils.getMimeType('film.mkv'), 'video/x-matroska');
      expect(ImageUtils.getMimeType('clip.webm'), 'video/webm');
    });

    // Test 8: Unknown file type
    test('returns default MIME type for unknown extensions', () {
      expect(ImageUtils.getMimeType('file.xyz'), 'application/octet-stream');
      expect(ImageUtils.getMimeType('unknown'), 'application/octet-stream');
      expect(ImageUtils.getMimeType('file_without_extension'), 'application/octet-stream');
    });

    // Test 9: Case insensitivity
    test('handles file extensions case-insensitively', () {
      expect(ImageUtils.getMimeType('PHOTO.JPG'), 'image/jpeg');
      expect(ImageUtils.getMimeType('Document.PDF'), 'application/pdf');
      expect(ImageUtils.getMimeType('DATA.JSON'), 'application/json');
    });

    // Test 10: File paths with directories
    test('handles file paths with directories', () {
      expect(ImageUtils.getMimeType('/path/to/photo.jpg'), 'image/jpeg');
      expect(ImageUtils.getMimeType('C:\\Users\\Documents\\file.pdf'), 'application/pdf');
      expect(ImageUtils.getMimeType('folder/subfolder/script.js'), 'text/javascript');
    });

    // Test 11: isImageFile method
    test('isImageFile correctly identifies image files', () {
      expect(ImageUtils.isImageFile('photo.jpg'), true);
      expect(ImageUtils.isImageFile('image.png'), true);
      expect(ImageUtils.isImageFile('icon.svg'), true);
      expect(ImageUtils.isImageFile('document.pdf'), false);
      expect(ImageUtils.isImageFile('data.json'), false);
      expect(ImageUtils.isImageFile('file.txt'), false);
    });

    // Test 12: Common file types that should be supported
    test('supports all common file types mentioned in requirements', () {
      // Images
      expect(ImageUtils.getMimeType('file.png'), 'image/png');
      expect(ImageUtils.getMimeType('file.jpg'), 'image/jpeg');
      
      // Text
      expect(ImageUtils.getMimeType('file.txt'), 'text/plain');
      expect(ImageUtils.getMimeType('file.md'), 'text/markdown');
      
      // Documents
      expect(ImageUtils.getMimeType('file.pdf'), 'application/pdf');
      
      // Archives
      expect(ImageUtils.getMimeType('file.zip'), 'application/zip');
      
      // Code
      expect(ImageUtils.getMimeType('file.js'), 'text/javascript');
      expect(ImageUtils.getMimeType('file.py'), 'text/x-python');
      
      // Audio
      expect(ImageUtils.getMimeType('file.mp3'), 'audio/mpeg');
      
      // Video
      expect(ImageUtils.getMimeType('file.mp4'), 'video/mp4');
    });
  });
}
