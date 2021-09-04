package;

import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var char:String = 'bf';
	public var isPlayer:Bool = false;
	public var isOldIcon:Bool = false;

	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	public function new(?char:String = "bf", ?isPlayer:Bool = false)
	{
		super();

		this.char = char;
		this.isPlayer = isPlayer;

		isPlayer = isOldIcon = false;

		antialiasing = FlxG.save.data.antialiasing;

		changeIcon(char);
		scrollFactor.set();
	}

	public function changeIcon(char:String)
	{
		frames = Paths.getSparrowAtlas('IconAssets', 'preload');

		if (isPlayer)
		{
			animation.addByPrefix('loss', '06Loosing', 24, true, isPlayer);
			animation.addByPrefix('normal', '06 Normal', 24, true, isPlayer);
			animation.addByPrefix('win', '06Winning', 24, true, isPlayer);
		}
		else
		{
			animation.addByPrefix('loss', 'DaidemLoosing', 24, true, isPlayer);
			animation.addByPrefix('normal', 'DaidemNormal', 24, true, isPlayer);
			animation.addByPrefix('win', 'DaidemWinning', 24, true, isPlayer);
		}

		animation.play('normal', true);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
