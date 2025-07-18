import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:memory_pins_app/models/pin_detail.dart';
import 'package:memory_pins_app/models/pin.dart';
import 'package:memory_pins_app/presentation/Widgets/add_photo_grid_item.dart';
import 'package:memory_pins_app/presentation/Widgets/audio_list_item.dart';
import 'package:memory_pins_app/presentation/Widgets/photo_grid_item.dart';
import 'package:memory_pins_app/presentation/Widgets/report_block_dialog.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';
import 'package:memory_pins_app/providers/pin_provider.dart';
import 'package:provider/provider.dart';

class PinDetailPopup extends StatefulWidget {
  final PinDetail pinDetail;
  final Pin? originalPin;

  const PinDetailPopup({
    Key? key,
    required this.pinDetail,
    this.originalPin,
  }) : super(key: key);

  @override
  State<PinDetailPopup> createState() => _PinDetailPopupState();
}

class _PinDetailPopupState extends State<PinDetailPopup> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkIfPinIsSaved();
    _incrementPinViews();
  }

  void _checkIfPinIsSaved() async {
    final pinProvider = Provider.of<PinProvider>(context, listen: false);
    final pinId = widget.originalPin?.id ?? widget.pinDetail.title;
    final isSaved = await pinProvider.isPinSaved(pinId);
    if (mounted) {
      setState(() {
        _isSaved = isSaved;
      });
    }
  }

  void _incrementPinViews() async {
    if (widget.originalPin != null) {
      final pinProvider = Provider.of<PinProvider>(context, listen: false);
      await pinProvider.incrementPinViews(widget.originalPin!.id);
    }
  }

  void _incrementPinPlays() async {
    if (widget.originalPin != null) {
      final pinProvider = Provider.of<PinProvider>(context, listen: false);
      await pinProvider.incrementPinPlays(widget.originalPin!.id);
    }
  }

  void _toggleSave() {
    final pinProvider = Provider.of<PinProvider>(context, listen: false);

    setState(() {
      _isSaved = !_isSaved;
    });

    final pinId = widget.originalPin?.id ?? widget.pinDetail.title;

    if (_isSaved) {
      pinProvider.savePin(pinId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pin saved!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      pinProvider.unsavePin(pinId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pin removed from saved'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showReportBlockDialog() {
    // Get the actual user ID and name from the pin data
    final reportedUserId = widget.originalPin?.userId ?? 'unknown_user';
    final reportedPinId = widget.originalPin?.id;
    final reportedUserName = widget.originalPin?.userName ?? 'Unknown User';

    showDialog(
      context: context,
      builder: (context) => ReportBlockDialog(
        reportedUserId: reportedUserId,
        reportedPinId: reportedPinId,
        reportedUserName: reportedUserName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF253743),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '📍Title: ${widget.pinDetail.title}',
                            style: GoogleFonts.nunitoSans(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _toggleSave,
                              child: Icon(
                                _isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 8),
                            GestureDetector(
                              onTap: _showReportBlockDialog,
                              child: Icon(
                                Icons.more_vert,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Description
                    Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Icon(Icons.format_quote,
                              color: Colors.white, size: 20),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Icon(Icons.format_quote,
                              color: Colors.white, size: 20),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 8.0),
                          child: Text(
                            widget.pinDetail.description,
                            style: text14W500White(context),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Audios Section
                    Text(
                      'Audios',
                      style: text18W700White(context),
                    ),
                    SizedBox(height: 15),
                    ListView.separated(
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 16),
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: widget.pinDetail.audios.length,
                      itemBuilder: (context, index) {
                        final audio = widget.pinDetail.audios[index];
                        return AudioListItem(
                          audio: audio,
                          onPlayIncrement: _incrementPinPlays,
                        );
                      },
                    ),
                    SizedBox(height: 30),

                    // Photos Section
                    Text(
                      'Photos',
                      style: text18W700White(context),
                    ),
                    SizedBox(height: 15),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: widget.pinDetail.photos.length,
                      itemBuilder: (context, index) {
                        final photo = widget.pinDetail.photos[index];
                        return PhotoGridItem(photo: photo);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show the popup
void showPinDetailPopup(BuildContext context, PinDetail pinDetail,
    {Pin? originalPin}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return PinDetailPopup(
        pinDetail: pinDetail,
        originalPin: originalPin,
      );
    },
  );
}
