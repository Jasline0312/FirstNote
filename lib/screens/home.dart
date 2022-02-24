import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'screens/notes_edit.dart';
import '../models/models/note.dart';
import '../models/notes_database.dart';
import '../theme/note_colors.dart';

const c1 = 0xFFFDFFFC, c2 = 0xFFFF595E, c3 = 0xFF374B4A, c4 = 0xFF00B1CC, c5 = 0xFFFFD65C, c6 = 0xFFB9CACA,
    c7 = 0x80374B4A, c8 = 0x3300B1CC, c9 = 0xCCFF595E;

/*
* Read all notes stored in database and sort them based on name
*/
Future<List<Map<String, dynamic>>> readDatabase() async {
  try {
    NotesDatabase notesDb = NotesDatabase();
    await notesDb.initDatabase();
    List<Map> notesList = await notesDb.getAllNotes();
    //await notesDb.deleteAllNotes();
    await notesDb.closeDatabase();
    List<Map<String, dynamic>> notesData = List<Map<String, dynamic>>.from(notesList);
    //notesData.sort((a, b) => (a['title']).compareTo(b['title']));
    return notesData;
  } catch(e) {

    return [{}];
  }
}

// Home Screen
class Home extends StatefulWidget{
  @override
  _Home createState() => _Home();
}

class _Home extends State<Home> {
  // Read Database and get Notes
  List<Map<String, dynamic>> notesData;
  List<int> selectedNoteIds = [];

  // Render the screen and update changes
  void afterNavigatorPop() {
    setState(() {});
  }

  // Long Press handler to display bottom bar
  void handleNoteListLongPress(int id) {
    setState(() {
      if (selectedNoteIds.contains(id) == false) {
        selectedNoteIds.add(id);
      }
    });
  }

  // Remove selection after long press
  void handleNoteListTapAfterSelect(int id) {
    setState(() {
      if (selectedNoteIds.contains(id) == true) {
        selectedNoteIds.remove(id);
      }
    });
  }

  // Delete Note/Notes
  void handleDelete() async {
    try {
      NotesDatabase notesDb = NotesDatabase();
      await notesDb.initDatabase();
      for (int id in selectedNoteIds) {
        int result = await notesDb.deleteNote(id);
      }
      await notesDb.closeDatabase();
    } catch (e) {

    } finally {
      setState(() {
        selectedNoteIds = [];
      });
    }
  }

  // Share Note/Notes
  void handleShare() async {
    String content = '';
    try {
      NotesDatabase notesDb = NotesDatabase();
      await notesDb.initDatabase();
      for (int id in selectedNoteIds) {
        dynamic notes = await notesDb.getNotes(id);
        if (notes != null) {
          content = content + notes['title'] + '\n' +  notes['content'] + '\n\n';
        }
      }
      await notesDb.closeDatabase();
    } catch (e) {

    } finally {
      setState(() {
        selectedNoteIds = [];
      });
    }
    await Share.share(content.trim(), subject: content.split('\n')[0]);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(c6),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors. redAccent,
        brightness: Brightness.dark,

        title: Text(
        'My Note',
        style: TextStyle(
        color: Colors.white,
        ),
        ),

        leading: (selectedNoteIds.length > 0?
        IconButton(
          onPressed: () {
            setState(() {
              selectedNoteIds = [];
            });
          },
          icon: Icon(
            Icons.close,
            color: Color(c5),
          ),
        ):
        //AppBarLeading()
        Container()
        ),

        actions: [
          appBarPopMenu(
            parentContext: context,
            //onSelectPopupmenuItem: onSelectAppBarPopupMenuItem,
          ),

          (selectedNoteIds.length == 0?
          Container():
          IconButton(
            onPressed: () {
              setState(() {
                selectedNoteIds = notesData.map((item) => item['id'] as int).toList();
              });
            },
            icon: Icon(
              Icons.done_all,
              color: Color(c5),
            ),
          )
          )
        ],
      ),

      /*
			//Drawer
			drawer: Drawer(
				child: DrawerList(),
			),
			*/

      //Floating Button
      floatingActionButton: (
          selectedNoteIds.length == 0?
          FloatingActionButton(
            child: const Icon(
              Icons.add,
              color: const Color(c5),
            ),
            tooltip: 'New Notes',
            backgroundColor: Colors.redAccent,
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/notes_edit',
                arguments: [
                  'new',
                  [{}],
                ],
              ).then((dynamic value) {
                afterNavigatorPop();
              }
              );
              return;
            },
          ):
          null
      ),

      body: FutureBuilder(
          future: readDatabase(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              notesData = snapshot.data;
              return Stack(
                children: <Widget>[
                  // Display Notes
                  AllNoteLists(
                    snapshot.data,
                    this.selectedNoteIds,
                    afterNavigatorPop,
                    handleNoteListLongPress,
                    handleNoteListTapAfterSelect,
                  ),

                  // Bottom Action Bar when Long Pressed
                  (selectedNoteIds.length > 0?
                  BottomActionBar(
                      handleDelete: handleDelete,
                      handleShare: handleShare
                  ):
                  Container()
                  ),
                ],
              );
            } else if (snapshot.hasError) {

            } else {
              return Center(
                child: CircularProgressIndicator(
                  backgroundColor: Color(c3),
                ),
              );
            }
          }
      ),
    );
  }
}

// Display all notes
class AllNoteLists extends StatelessWidget {
  final data;
  final selectedNoteIds;
  final afterNavigatorPop;
  final handleNoteListLongPress;
  final handleNoteListTapAfterSelect;

  AllNoteLists(
      this.data,
      this.selectedNoteIds,
      this.afterNavigatorPop,
      this.handleNoteListLongPress,
      this.handleNoteListTapAfterSelect,
      );

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          dynamic item = data[index];
          return DisplayNotes(
            item,
            selectedNoteIds,
            (selectedNoteIds.contains(item['id']) == false? false: true),
            afterNavigatorPop,
            handleNoteListLongPress,
            handleNoteListTapAfterSelect,
          );
        }
    );
  }
}


// A Note view showing title, first line of note and color
class DisplayNotes extends StatelessWidget {
  final notesData;
  final selectedNoteIds;
  final selectedNote;
  final callAfterNavigatorPop;
  final handleNoteListLongPress;
  final handleNoteListTapAfterSelect;

  DisplayNotes(
      this.notesData,
      this.selectedNoteIds,
      this.selectedNote,
      this.callAfterNavigatorPop,
      this.handleNoteListLongPress,
      this.handleNoteListTapAfterSelect,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Material(
        elevation: 1,
        color: (selectedNote == false? Color(c1): Color(c8)),
        clipBehavior: Clip.hardEdge,
        borderRadius: BorderRadius.circular(5.0),
        child: InkWell(
          onTap: () {
            if (selectedNote == false) {
              if (selectedNoteIds.length == 0) {
                Navigator.pushNamed(
                  context,
                  '/notes_edit',
                  arguments: [
                    'update',
                    notesData,
                  ],
                ).then((dynamic value) {
                  callAfterNavigatorPop();
                }
                );
                return;
              }
              else {
                handleNoteListLongPress(notesData['id']);
              }
            }
            else {
              handleNoteListTapAfterSelect(notesData['id']);
            }
          },

          onLongPress: () {
            handleNoteListLongPress(notesData['id']);
          },
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: (selectedNote == false?
                          Color(NoteColors[notesData['noteColor']]['b']):
                          Color(c9)
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: (
                              selectedNote == false?
                              Text(
                                notesData['title'][0],
                                style: TextStyle(
                                  color: Color(c1),
                                  fontSize: 21,
                                ),
                              ):
                              Icon(
                                Icons.check,
                                color: Color(c1),
                                size: 21,
                              )
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children:<Widget>[
                      Text(
                        notesData['title'] != null? notesData['title']: "",
                        style: TextStyle(
                          color: Color(c3),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Container(
                        height: 3,
                      ),

                      Text(
                        notesData['content'] != null? notesData['content'].split('\n')[0]: "",
                        style: TextStyle(
                          color: Color(c7),
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// BottomAction bar contains options like Delete, Share...
class BottomActionBar extends StatelessWidget {
  final VoidCallback handleDelete;
  final VoidCallback handleShare;

  BottomActionBar({
    this.handleDelete,
    this.handleShare,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: Material(
          elevation: 2,
          color: Color(c7),
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // Delete
                InkResponse(
                  onTap: () => handleDelete(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.delete,
                        color: Color(c1),
                        semanticLabel: 'Delete',
                      ),

                      Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Color(c1),
                        ),
                      ),
                    ],
                  ),
                ),

                // Share
                InkResponse(
                  onTap: () => handleShare(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.share,
                        color: Color(c1),
                        semanticLabel: 'Share',
                      ),

                      Text(
                        'Share',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Color(c1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void onSelectAppBarPopupMenuItem(BuildContext currentContext, String optionName) {
  List<Map<String, dynamic>> notesData;

  switch (optionName) {
    case 'Sort by A-Z':
      notesData.sort((a, b) => (a['title']).compareTo(b['title']));
      break;
    case 'Sort by Z-A':
      notesData.sort((b, a) => (a['title']).compareTo(b['title']));
      break;
  }
}

// More Menu to display various options like Color, Sort, Share...
class appBarPopMenu extends StatelessWidget {
  final popupMenuButtonItems = const {
    1: const {'name': 'Sort by A-Z', 'icon': Icons.sort_by_alpha},
    2: const {'name': 'Sort by Z-A', 'icon': Icons.sort_by_alpha},
  };
  final parentContext;
  final void Function(BuildContext, String) onSelectPopupmenuItem;

  appBarPopMenu({
    @required this.parentContext,
    @required this.onSelectPopupmenuItem,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(
        Icons.more_vert,
        color: const Color(c1),
      ),
      color: Color(c1),
      itemBuilder: (context) {
        var list = popupMenuButtonItems.entries.map((entry) {
          return PopupMenuItem(
            child: Container(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width * 0.3,
              ),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      entry.value['icon'],
                      color: const Color(c3),
                    ),
                  ),
                  Text(
                    entry.value['name'],
                    style: TextStyle(
                      color: Color(c3),
                    ),
                  ),
                ],
              ),
            ),
            value: entry.key,
          );
        }).toList();
        return list;
      },
      onSelected: (value) {
        onSelectPopupmenuItem(parentContext, popupMenuButtonItems[value]['name']);
      },
    );
  }
}
