package;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import openfl.utils.Future;
import openfl.media.Sound;
import flixel.system.FlxSound;
#if sys
import smTools.SMFile;
import sys.FileSystem;
import sys.io.File;
#end
import Song.SwagSong;
import flixel.input.gamepad.FlxGamepad;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;


#if windows
import Discord.DiscordClient;
#end

using StringTools;

class FreeplayState extends MusicBeatState
{
	public static var songs:Array<SongMetadata> = [];
	public static var bpms:Array<Float> = [];

	var selector:FlxText;

	public static var rate:Float = 1.0;

	public static var curSelected:Int = 0;
	public static var curDifficulty:Int = 2;

	var scoreText:FlxText;
	var comboText:FlxText;
	var diffCalcText:FlxText;
	var previewtext:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var combo:String = '';

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	public static var openedPreview = false;

	public static var songData:Map<String,Array<SwagSong>> = [];
	
	var camZoom:FlxTween;

	public static function loadDiff(diff:Int, format:String, name:String, array:Array<SwagSong>)
	{
		try 
		{
			array.push(Song.loadFromJson(Highscore.formatSong(format, diff), name));
		}
		catch(ex)
		{
			// do nada
		}
	}

	override function create()
	{
		clean();
		var initSonglist = CoolUtil.coolTextFile(Paths.txt('data/freeplaySonglist'));

		//var diffList = "";

		songData = [];
		songs = [];

		for (i in 0...initSonglist.length)
		{
			var data:Array<String> = initSonglist[i].split(':');
			var meta = new SongMetadata(data[0], Std.parseInt(data[2]), data[1]);
			var format = StringTools.replace(meta.songName, " ", "-");
			switch (format) {
				case 'Dad-Battle': format = 'Dadbattle';
				case 'Philly-Nice': format = 'Philly';
			}

			var diffs = [];
			var diffsThatExist = [];


			#if sys
			if (FileSystem.exists('assets/data/${format}/${format}-hard.json'))
				diffsThatExist.push("Hard");
			if (FileSystem.exists('assets/data/${format}/${format}-easy.json'))
				diffsThatExist.push("Easy");
			if (FileSystem.exists('assets/data/${format}/${format}.json'))
				diffsThatExist.push("Normal");

			if (diffsThatExist.length == 0)
			{
				Application.current.window.alert("No difficulties found for chart, skipping.",meta.songName + " Chart");
				continue;
			}
			#else
			diffsThatExist = ["Easy","Normal","Hard"];
			#end
			if (diffsThatExist.contains("Easy"))
				FreeplayState.loadDiff(0,format,meta.songName,diffs);
			if (diffsThatExist.contains("Normal"))
				FreeplayState.loadDiff(1,format,meta.songName,diffs);
			if (diffsThatExist.contains("Hard"))
				FreeplayState.loadDiff(2,format,meta.songName,diffs);

			meta.diffs = diffsThatExist;

			if (diffsThatExist.length != 3)
				trace("I ONLY FOUND " + diffsThatExist);

			FreeplayState.songData.set(meta.songName,diffs);
			trace('loaded diffs for ' + meta.songName);
			songs.push(meta);

		}

		//trace("\n" + diffList);

		/* 
			if (FlxG.sound.music != null)
			{
				if (!FlxG.sound.music.playing)
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
		 */

		 #if windows
		 // Updating Discord Rich Presence
		 DiscordClient.changePresence("In the Freeplay Menu", null);
		 #end

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end

		persistentUpdate = true;

		// LOAD MUSIC

		// LOAD CHARACTERS

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		bg.antialiasing = FlxG.save.data.antialiasing;
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false, true);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;
			iconArray.push(icon);
			icon.animation.play('normalLooped', true);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		// scoreText.autoSize = false;
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		// scoreText.alignment = RIGHT;

		var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.35), 135, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffCalcText = new FlxText(scoreText.x, scoreText.y + 66, 0, "", 24);
		diffCalcText.font = scoreText.font;
		add(diffCalcText);

		previewtext = new FlxText(scoreText.x, scoreText.y + 94, 0, "Rate: " + rate + "x", 24);
		previewtext.font = scoreText.font;
		add(previewtext);

		comboText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		comboText.font = scoreText.font;
		add(comboText);

		add(scoreText);

		changeSelection();
		changeDiff();

		// FlxG.sound.playMusic(Paths.music('title'), 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);
		selector = new FlxText();

		selector.size = 40;
		selector.text = ">";
		// add(selector);

		camZoom = FlxTween.tween(this, {}, 0);

		super.create();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter));
		bpms.push(Song.loadFromJson(songName, songName.toLowerCase() + "-hard").bpm);
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['dad'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);

			if (songCharacters.length != 1)
				num++;
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music != null)
            Conductor.songPosition = FlxG.sound.music.time;

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		scoreText.text = "PERSONAL BEST:" + lerpScore;
		comboText.text = combo + '\n';

		var upP = FlxG.keys.justPressed.UP;
		var downP = FlxG.keys.justPressed.DOWN;

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{

			if (gamepad.justPressed.DPAD_UP)
			{
				changeSelection(-1);
			}
			if (gamepad.justPressed.DPAD_DOWN)
			{
				changeSelection(1);
			}
			if (gamepad.justPressed.DPAD_LEFT)
			{
				changeDiff(-1);
			}
			if (gamepad.justPressed.DPAD_RIGHT)
			{
				changeDiff(1);
			}

			//if (gamepad.justPressed.X && !openedPreview)
				//openSubState(new DiffOverview());
		}

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		//if (FlxG.keys.justPressed.SPACE && !openedPreview)
			//openSubState(new DiffOverview());

		if (FlxG.keys.pressed.SHIFT)
		{
			if (FlxG.keys.justPressed.LEFT)
			{
				rate -= 0.05;
				diffCalcText.text = 'RATING: ${DiffCalc.CalculateDiff(songData.get(songs[curSelected].songName)[curDifficulty])}';
			}
			if (FlxG.keys.justPressed.RIGHT)
			{
				rate += 0.05;
				diffCalcText.text = 'RATING: ${DiffCalc.CalculateDiff(songData.get(songs[curSelected].songName)[curDifficulty])}';
			}

			if (rate > 3)
			{
				rate = 3;
				diffCalcText.text = 'RATING: ${DiffCalc.CalculateDiff(songData.get(songs[curSelected].songName)[curDifficulty])}';
			}
			else if (rate < 0.5)
			{
				rate = 0.5;
				diffCalcText.text = 'RATING: ${DiffCalc.CalculateDiff(songData.get(songs[curSelected].songName)[curDifficulty])}';
			}

			previewtext.text = "Rate: " + rate + "x";
		}
		else
		{
		}
		
					
		#if cpp
		@:privateAccess
		{
			if (FlxG.sound.music.playing)
				lime.media.openal.AL.sourcef(FlxG.sound.music._channel.__source.__backend.handle, lime.media.openal.AL.PITCH, rate);
		}
		#end

		if (controls.BACK)
		{
			FlxG.switchState(new MainMenuState());
		}

		if (controls.ACCEPT)
		{
			accepted = true;
			// adjusting the song name to be compatible
			var songFormat = StringTools.replace(songs[curSelected].songName, " ", "-");

			var hmm;
			try
			{
				hmm = songData.get(songs[curSelected].songName)[curDifficulty];
				if (hmm == null)
					return;
			}
			catch(ex)
			{
				return;
			}

			for (i in 0...grpSongs.members.length)
			{
				if (i == curSelected)
				{
					FlxFlicker.flicker(grpSongs.members[i], 0.75, 0.06, false, false);
					FlxFlicker.flicker(iconArray[i], 0.75, 0.06, false, false);
				}
				else
				{
					FlxTween.tween(grpSongs.members[i], {alpha: 0.0}, 0.4, {ease: FlxEase.quadIn});
					FlxTween.tween(iconArray[i], {alpha: 0.0}, 0.4, {ease: FlxEase.quadIn});
				}
			}

			PlayState.SONG = Song.conversionChecks(hmm);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;
			PlayState.storyWeek = songs[curSelected].week;
			trace('CUR WEEK' + PlayState.storyWeek);
			#if sys
			if (songs[curSelected].songCharacter == "sm")
				{
					PlayState.isSM = true;
					PlayState.sm = songs[curSelected].sm;
					PlayState.pathToSm = songs[curSelected].path;
				}
			else
				PlayState.isSM = false;
			#else
			PlayState.isSM = false;
			#end

			PlayState.songMultiplier = rate;

			FlxG.sound.play(Paths.sound('confirmMenu'));

			FlxG.camera.fade(FlxColor.BLACK, 0.75, false);

			FlxG.sound.music.fadeOut(0.75, 0);

			new FlxTimer().start(0.75, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState());
			});

			clean();
		}
	}

	function changeDiff(change:Int = 0)
	{
		if (!songs[curSelected].diffs.contains(CoolUtil.difficultyFromInt(curDifficulty + change)))
			return;

		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;


		// adjusting the highscore song name to be compatible (changeDiff)
		var songHighscore = StringTools.replace(songs[curSelected].songName, " ", "-");
		switch (songHighscore) {
			case 'Dad-Battle': songHighscore = 'Dadbattle';
			case 'Philly-Nice': songHighscore = 'Philly';
		}
		
		#if !switch
		intendedScore = Highscore.getScore(songHighscore, curDifficulty);
		combo = Highscore.getCombo(songHighscore, curDifficulty);
		#end
		diffCalcText.text = 'RATING: ${DiffCalc.CalculateDiff(songData.get(songs[curSelected].songName)[curDifficulty])}';
	}

	override function beatHit()
	{
		super.beatHit();
		if (!accepted)
		{
			bopOnBeat();
		}
	}

	function bopOnBeat()
	{
		if (!accepted)
		{
			FlxG.camera.zoom += 0.015;
			camZoom = FlxTween.tween(FlxG.camera, {zoom: 1}, 0.1);
		}
	}

	var accepted:Bool = false;

	function changeSelection(change:Int = 0)
	{
		#if !switch
		// NGio.logEvent('Fresh');
		#end

		// NGio.logEvent('Fresh');
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		Conductor.changeBPM(bpms[curSelected]);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		if (songs[curSelected].diffs.length != 3)
		{
			switch(songs[curSelected].diffs[0])
			{
				case "Easy":
					curDifficulty = 0;
				case "Normal":
					curDifficulty = 1;
				case "Hard":
					curDifficulty = 2;
			}
		}

		// selector.y = (70 * curSelected) + 30;
		
		// adjusting the highscore song name to be compatible (changeSelection)
		// would read original scores if we didn't change packages
		var songHighscore = StringTools.replace(songs[curSelected].songName, " ", "-");
		switch (songHighscore) {
			case 'Dad-Battle': songHighscore = 'Dadbattle';
			case 'Philly-Nice': songHighscore = 'Philly';
		}

		#if !switch
		intendedScore = Highscore.getScore(songHighscore, curDifficulty);
		combo = Highscore.getCombo(songHighscore, curDifficulty);
		// lerpScore = 0;
		#end

		diffCalcText.text = 'RATING: ${DiffCalc.CalculateDiff(songData.get(songs[curSelected].songName)[curDifficulty])}';
		
		FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0.8);

		var hmm;
			try
			{
				hmm = songData.get(songs[curSelected].songName)[curDifficulty];
				if (hmm != null)
					Conductor.changeBPM(hmm.bpm);
			}
			catch(ex)
			{}

		if (openedPreview)
		{
			closeSubState();
			openSubState(new DiffOverview());
		}

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	#if sys
	public var sm:SMFile;
	public var path:String;
	#end
	public var songCharacter:String = "";

	public var diffs = [];

	#if sys
	public function new(song:String, week:Int, songCharacter:String, ?sm:SMFile = null, ?path:String = "")
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.sm = sm;
		this.path = path;
	}
	#else
	public function new(song:String, week:Int, songCharacter:String)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
	}
	#end
}
