import flixel.FlxG;
import flixel.math.FlxMath;

class HelperFunctions
{
    public static function truncateFloat( number : Float, precision : Int): Float {
		var num = number;
		num = num * Math.pow(10, precision);
		num = Math.round( num ) / Math.pow(10, precision);
		return num;
	}

	public static function GCD(a, b) {
		return b == 0 ? FlxMath.absInt(a) : GCD(b, a % b);
	}

	public static function getArtist(song:String) 
	{
		var artistPrefix:String = 'Kawai Sprite';
		switch (song)
		{
			case 'experimental-phase':
				artistPrefix = 'TheInnuendo';
			case 'perfection':
				artistPrefix = 'Tenzubushi';
			default:
				artistPrefix = 'Kawai Sprite';
		}	

		return artistPrefix;
	}
}