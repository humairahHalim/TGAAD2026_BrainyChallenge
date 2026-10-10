import 'package:brainy_challenge/homepageWnavi.dart';
import 'package:flutter/material.dart';

class HeroLayoutCard extends StatelessWidget {
  const HeroLayoutCard({
    super.key,
    required this.myCard,
  });

  final myCarouselCard myCard;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(39, 64, 195, 255),
        border: Border.all(
          color: Colors.lightBlueAccent,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        alignment: AlignmentDirectional.bottomStart,
        children: <Widget>[
          ClipRect(
            child: OverflowBox(
              maxWidth: width * 3 / 8,
              minWidth: width * 3 / 8,
              child: Image(
                alignment: Alignment.topCenter,
                fit: BoxFit.fitHeight,
                image: NetworkImage(
                  myCard.picture,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  myCard.title,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineLarge?.copyWith(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }
}
