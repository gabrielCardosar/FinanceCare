import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/notes_provider.dart';
import '../models/note_model.dart';
import '../utils/constants.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NotesProvider>().notes;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Bloco de Notas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNote(context, null),
        child: const Icon(Icons.add),
      ),
      body: notes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_alt,
                      size: 64,
                      color: AppColors.warning.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text('Nenhuma nota ainda'),
                  const SizedBox(height: 8),
                  const Text('Toque em + para criar uma nota'),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return GestureDetector(
                  onTap: () => _openNote(context, note),
                  onLongPress: () => _confirmDelete(context, note),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _noteColor(index, isDark),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title.isEmpty ? 'Sem título' : note.title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark
                                  ? Colors.white
                                  : Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            note.content,
                            style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black54),
                            overflow: TextOverflow.fade,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('dd/MM HH:mm')
                              .format(note.updatedAt),
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.black38),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _noteColor(int index, bool isDark) {
    final colors = isDark
        ? [
            const Color(0xFF2D2F3E),
            const Color(0xFF2E3440),
            const Color(0xFF2F3B2E),
            const Color(0xFF3B2E2E),
            const Color(0xFF2E2E3B),
          ]
        : [
            const Color(0xFFFFF9C4),
            const Color(0xFFB3E5FC),
            const Color(0xFFC8E6C9),
            const Color(0xFFFFCCBC),
            const Color(0xFFE1BEE7),
          ];
    return colors[index % colors.length];
  }

  void _openNote(BuildContext context, NoteModel? note) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
    );
  }

  void _confirmDelete(BuildContext context, NoteModel note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deletar nota'),
        content: Text(
            'Deseja deletar "${note.title.isEmpty ? 'Sem título' : note.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () {
              final uid =
                  context.read<AuthProvider>().user?.uid;
              if (uid != null) {
                context.read<NotesProvider>().deleteNote(uid, note.id);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Deletar'),
          ),
        ],
      ),
    );
  }
}

// ─── EDITOR ──────────────────────────────────────────────────────────

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? note;
  const NoteEditorScreen({Key? key, this.note}) : super(key: key);

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl =
        TextEditingController(text: widget.note?.title ?? '');
    _contentCtrl =
        TextEditingController(text: widget.note?.content ?? '');
    _titleCtrl.addListener(_onChange);
    _contentCtrl.addListener(_onChange);
  }

  void _onChange() => setState(() => _hasChanges = true);

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid =
        context.read<AuthProvider>().user?.uid ?? '';
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text;

    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    if (widget.note == null) {
      await context.read<NotesProvider>().addNote(NoteModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            uid: uid,
            title: title,
            content: content,
          ));
    } else {
      await context.read<NotesProvider>().updateNote(
            widget.note!.copyWith(title: title, content: content),
          );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Nova Nota' : 'Editar Nota'),
        actions: [
          if (_hasChanges || widget.note == null)
            TextButton(
              onPressed: _save,
              child: const Text('Salvar',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                  hintText: 'Título', border: InputBorder.none),
            ),
            const Divider(),
            Expanded(
              child: TextField(
                controller: _contentCtrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                    hintText: 'Escreva sua nota aqui...',
                    border: InputBorder.none),
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
