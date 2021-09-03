package;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.group.FlxGroup;
import flixel.system.FlxSound;
import flixel.addons.effects.chainable.FlxWaveEffect;

class Stage
{
    public var curStage:String = '';
    public var halloweenLevel:Bool = false;
    public var camZoom:Float;
    public var hideLastBG:Bool = false; // True = hide last BG and show ones from slowBacks on certain step, False = Toggle Visibility of BGs from SlowBacks on certain step
    public var tweenDuration:Float = 2; // How long will it tween hiding/showing BGs, variable above must be set to True for tween to activate
    public var toAdd:Array<Dynamic> = []; // Add BGs on stage startup, load BG in by using "toAdd.push(bgVar);"
    // Layering algorithm for noobs: Everything loads by the method of "On Top", example: You load wall first(Every other added BG layers on it), then you load road(comes on top of wall and doesn't clip through it), then loading street lights(comes on top of wall and road)
    public var swagBacks:Map<String, Dynamic> = []; // Store BGs here to use them later in PlayState or when slowBacks activate
    public var swagGroup:Map<String, FlxTypedGroup<Dynamic>> = []; //Store Groups
    public var animatedBacks:Array<FlxSprite> = []; // Store animated backgrounds and make them play animation(Animation must be named Idle!! Else use swagGroup)
    public var layInFront:Array<Array<FlxSprite>> = [[], [], []]; // BG layering, format: first [0] - in front of GF, second [1] - in front of opponent, third [2] - in front of boyfriend(and techincally also opponent since Haxe layering moment)
    public var slowBacks:Map<Int, Array<FlxSprite>> = []; // Change/add/remove backgrounds mid song! Format: "slowBacks[StepToBeActivated] = [Sprites,To,Be,Changed,Or,Added];"

    public function new(daStage:String)
    {
        this.curStage = daStage;
        camZoom = 1.05; // Don't change zoom here, unless you want to change zoom of every stage that doesn't have custom one
        halloweenLevel = false;

        switch(daStage)
        {
			default:
			{
				camZoom = 0.82;
				curStage = 'stage';

				var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('Stage_LayerTop'));
				bg.antialiasing = FlxG.save.data.antialiasing;
				bg.scrollFactor.set(0.9, 0.9);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);
			}
        }
    }
}