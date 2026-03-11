package mobile;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.input.touch.FlxTouch;
import flixel.util.FlxColor;
import flixel.text.FlxText;

/**
 * HitboxOverlay — 4-zone transparent touch hitbox for FNF Android.
 * Covers the right half of the screen with LEFT / DOWN / UP / RIGHT zones.
 * Add this to your PlayState and call update() each frame.
 */
class HitboxOverlay extends FlxSpriteGroup
{
	public var buttonLeft:HitboxButton;
	public var buttonDown:HitboxButton;
	public var buttonUp:HitboxButton;
	public var buttonRight:HitboxButton;

	// Track which touch IDs are currently held per button
	var _touchIDLeft:Int  = -1;
	var _touchIDDown:Int  = -1;
	var _touchIDUp:Int    = -1;
	var _touchIDRight:Int = -1;

	// Pressed states (public so Controls.hx can read them)
	public var leftPressed(default, null):Bool  = false;
	public var downPressed(default, null):Bool  = false;
	public var upPressed(default, null):Bool    = false;
	public var rightPressed(default, null):Bool = false;

	public var leftJustPressed(default, null):Bool  = false;
	public var downJustPressed(default, null):Bool  = false;
	public var upJustPressed(default, null):Bool    = false;
	public var rightJustPressed(default, null):Bool = false;

	public var leftJustReleased(default, null):Bool  = false;
	public var downJustReleased(default, null):Bool  = false;
	public var upJustReleased(default, null):Bool    = false;
	public var rightJustReleased(default, null):Bool = false;

	// Colors for each zone (very low alpha)
	static final COLOR_LEFT:FlxColor  = 0x44C24B99; // Purple
	static final COLOR_DOWN:FlxColor  = 0x4412FA05; // Green
	static final COLOR_UP:FlxColor    = 0x44F9393F; // Red
	static final COLOR_RIGHT:FlxColor = 0x4400FFFF; // Cyan

	public function new()
	{
		super(0, 0);
		scrollFactor.set();

		var sw:Float = FlxG.width;
		var sh:Float = FlxG.height;
		var zoneW:Float = sw / 4;

		buttonLeft  = new HitboxButton(0,        0, Std.int(zoneW), Std.int(sh), COLOR_LEFT,  "◄");
		buttonDown  = new HitboxButton(zoneW,    0, Std.int(zoneW), Std.int(sh), COLOR_DOWN,  "▼");
		buttonUp    = new HitboxButton(zoneW*2,  0, Std.int(zoneW), Std.int(sh), COLOR_UP,    "▲");
		buttonRight = new HitboxButton(zoneW*3,  0, Std.int(zoneW), Std.int(sh), COLOR_RIGHT, "►");

		add(buttonLeft);
		add(buttonDown);
		add(buttonUp);
		add(buttonRight);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// Reset just-pressed / just-released each frame
		leftJustPressed  = false;
		downJustPressed  = false;
		upJustPressed    = false;
		rightJustPressed = false;
		leftJustReleased  = false;
		downJustReleased  = false;
		upJustReleased    = false;
		rightJustReleased = false;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				// Which zone was touched?
				if (buttonLeft.overlapsPoint(touch.getWorldPosition()))
				{
					if (_touchIDLeft == -1) { _touchIDLeft = touch.touchPointID; leftJustPressed = true; }
				}
				if (buttonDown.overlapsPoint(touch.getWorldPosition()))
				{
					if (_touchIDDown == -1) { _touchIDDown = touch.touchPointID; downJustPressed = true; }
				}
				if (buttonUp.overlapsPoint(touch.getWorldPosition()))
				{
					if (_touchIDUp == -1) { _touchIDUp = touch.touchPointID; upJustPressed = true; }
				}
				if (buttonRight.overlapsPoint(touch.getWorldPosition()))
				{
					if (_touchIDRight == -1) { _touchIDRight = touch.touchPointID; rightJustPressed = true; }
				}
			}

			if (touch.justReleased)
			{
				if (touch.touchPointID == _touchIDLeft)  { _touchIDLeft  = -1; leftJustReleased  = true; }
				if (touch.touchPointID == _touchIDDown)  { _touchIDDown  = -1; downJustReleased  = true; }
				if (touch.touchPointID == _touchIDUp)    { _touchIDUp    = -1; upJustReleased    = true; }
				if (touch.touchPointID == _touchIDRight) { _touchIDRight = -1; rightJustReleased = true; }
			}
		}

		leftPressed  = (_touchIDLeft  != -1);
		downPressed  = (_touchIDDown  != -1);
		upPressed    = (_touchIDUp    != -1);
		rightPressed = (_touchIDRight != -1);

		// Visual feedback
		buttonLeft.alpha  = leftPressed  ? 0.6 : 0.15;
		buttonDown.alpha  = downPressed  ? 0.6 : 0.15;
		buttonUp.alpha    = upPressed    ? 0.6 : 0.15;
		buttonRight.alpha = rightPressed ? 0.6 : 0.15;
		#end
	}
}

/**
 * A single transparent rectangle zone with an arrow label.
 */
class HitboxButton extends FlxSprite
{
	public function new(x:Float, y:Float, w:Int, h:Int, color:FlxColor, label:String)
	{
		super(x, y);
		makeGraphic(w, h, color);
		this.alpha = 0.15;
		scrollFactor.set();

		// Draw border lines for visibility
		var border = new FlxSprite(x, y);
		border.makeGraphic(w, h, FlxColor.TRANSPARENT);
		// (border drawing omitted for simplicity — use FlxSpriteUtil if desired)
	}
}
