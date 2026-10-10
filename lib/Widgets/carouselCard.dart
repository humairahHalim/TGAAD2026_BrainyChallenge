import 'package:brainy_challenge/homepageWnavi.dart';
import 'package:flutter/material.dart';

class HeroLayoutCard extends StatelessWidget {
  const HeroLayoutCard({super.key, required this.myCard});

  final myCarouselCard myCard;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    return Stack(
      alignment: AlignmentDirectional.bottomStart,
      children: <Widget>[
        ClipRect(
          child: OverflowBox(
            maxWidth: width * 7 / 8,
            minWidth: width * 7 / 8,
            child: Image(
              fit: BoxFit.cover,
              image: NetworkImage(
                'https://flutter.github.io/assets-for-api-docs/assets/material/${myCard.picture}',
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                myCard.title,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
