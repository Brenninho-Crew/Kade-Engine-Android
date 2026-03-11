package;

import openfl.display.Bitmap;
import lime.app.Application;
#if FEATURE_DISCORD
import Discord.DiscordClient;
#end
import openfl.display.BlendMode;
import openfl.text.TextFormat;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;

class Main extends Sprite
{
	var gameWidth:Int  = 1280;
	var gameHeight:Int = 720;
	var initialState:Class<FlxState> = TitleState;
	var zoom:Float     = -1;

	/**
	 * No Android, o framerate é limitado a 60 pelo compilador
	 * (veja setupGame). Em desktop/web pode subir até 120.
	 */
	var framerate:Int  = 120;

	var skipSplash:Bool       = true;
	var startFullscreen:Bool  = false;

	// ─── Statics ───────────────────────────────────────────────────────────────

	public static var instance:Main;

	/** Apenas instanciado em desktop/html5 — nunca em mobile. */
	public static var bitmapFPS:Bitmap;

	public static var watermarks:Bool = true;

	/**
	 * WebmHandler é desktop-only (extension-webm não compila pra Android).
	 * A flag FEATURE_WEBM já protege o código no resto do projeto;
	 * aqui garantimos que o campo nem existe em builds mobile.
	 */
	#if FEATURE_WEBM
	public static var webmHandler:WebmHandler;
	#end

	// ─── Entry point ───────────────────────────────────────────────────────────

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		instance = this;
		super();

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	// ─── Init ──────────────────────────────────────────────────────────────────

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int  = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		// ── Zoom automático ─────────────────────────────────────────────────────
		if (zoom == -1)
		{
			var ratioX:Float = stageWidth  / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom       = Math.min(ratioX, ratioY);
			gameWidth  = Math.ceil(stageWidth  / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		// ── Framerate ───────────────────────────────────────────────────────────
		// cpp (Windows/Linux/Mac/Android) suporta >60; outros targets limitam a 60.
		#if !cpp
		framerate = 60;
		#end

		// No Android 120 fps é raro e drena bateria — limitamos a 60 por padrão.
		// Remova este bloco se quiser deixar o usuário escolher nas opções.
		#if android
		framerate = 60;
		#end

		// ── Debug / Log (sem acesso a disco no Android — usa logcat) ────────────
		Debug.onInitProgram();

		// ── ModCore ─────────────────────────────────────────────────────────────
		// ModCore usa o sistema de arquivos nativo para descobrir pastas de mods.
		// No Android os assets ficam dentro do APK (AssetManager), por isso
		// ModCore é completamente ignorado — nenhum arquivo é extraído.
		#if FEATURE_MODCORE
		ModCore.initialize();
		#end

		// ── FPS counter (desktop/html5 apenas) ──────────────────────────────────
		#if !mobile
		fpsCounter = new KadeEngineFPS(10, 3, 0xFFFFFF);
		bitmapFPS  = ImageOutline.renderImage(fpsCounter, 1, 0x000000, true);
		bitmapFPS.smoothing = true;
		#end

		// ── FlxGame ─────────────────────────────────────────────────────────────
		game = new FlxGame(gameWidth, gameHeight, initialState, zoom, framerate, framerate, skipSplash, startFullscreen);
		addChild(game);

		#if !mobile
		addChild(fpsCounter);
		toggleFPS(FlxG.save.data.fps);
		#end

		// ── Fim do boot ─────────────────────────────────────────────────────────
		Debug.onGameStart();
	}

	// ─── Campos privados ───────────────────────────────────────────────────────

	var game:FlxGame;

	#if !mobile
	var fpsCounter:KadeEngineFPS;
	#end

	// ─── API pública ───────────────────────────────────────────────────────────

	/**
	 * Libera bitmaps em cache manualmente.
	 * Útil após trocar de semana/fase para evitar OOM no Android.
	 * Crédito: Forever Engine / Shubs.
	 */
	public static function dumpCache():Void
	{
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null)
			{
				Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}
		Assets.cache.clear("songs");
	}

	public function toggleFPS(fpsEnabled:Bool):Void
	{
		#if !mobile
		if (fpsCounter != null)
			fpsCounter.visible = fpsEnabled;
		#end
	}

	public function changeFPSColor(color:FlxColor):Void
	{
		#if !mobile
		if (fpsCounter != null)
			fpsCounter.textColor = color;
		#end
	}

	public function setFPSCap(cap:Float):Void
	{
		openfl.Lib.current.stage.frameRate = cap;
	}

	public function getFPSCap():Float
	{
		return openfl.Lib.current.stage.frameRate;
	}

	public function getFPS():Float
	{
		#if !mobile
		if (fpsCounter != null)
			return fpsCounter.currentFPS;
		#end
		return openfl.Lib.current.stage.frameRate;
	}
}