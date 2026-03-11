package;

import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import haxe.Json;

using StringTools;

class Paths
{
	/**
	 * Extensão de áudio por plataforma:
	 *   web     → mp3  (único formato garantido nos browsers)
	 *   android → ogg  (suporte nativo, menor tamanho)
	 *   desktop → ogg
	 *
	 * Nunca lemos do disco — tudo via OpenFlAssets (APK AssetManager no Android).
	 */
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;

	static var currentLevel:String;

	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	static function getPath(file:String, type:AssetType, library:Null<String>)
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath = getLibraryPathForce(file, currentLevel);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	/**
	 * Carrega uma imagem a partir do APK (via OpenFlAssets) ou do cache de bitmap.
	 *
	 * No Android todos os assets ficam dentro do APK;
	 * o OpenFlAssets.getBitmapData() usa o AssetManager nativo — nenhum arquivo
	 * é extraído para o armazenamento interno/externo do dispositivo.
	 *
	 * O cache de disco (Caching.bitmapData) só existe em desktop onde
	 * FEATURE_FILESYSTEM está definido.
	 */
	static public function loadImage(key:String, ?library:String):FlxGraphic
	{
		var path = image(key, library);

		// Cache de disco — disponível somente em desktop.
		#if FEATURE_FILESYSTEM
		if (Caching.bitmapData != null)
		{
			if (Caching.bitmapData.exists(key))
			{
				Debug.logTrace('Loading image from bitmap cache: $key');
				return Caching.bitmapData.get(key);
			}
		}
		#end

		if (OpenFlAssets.exists(path, IMAGE))
		{
			var bitmap = OpenFlAssets.getBitmapData(path);
			return FlxGraphic.fromBitmapData(bitmap);
		}
		else
		{
			Debug.logWarn('Could not find image at path $path');
			return null;
		}
	}

	/**
	 * Lê e faz parse de um JSON via OpenFlAssets.getText().
	 * Funciona em todas as plataformas sem tocar no disco.
	 */
	static public function loadJSON(key:String, ?library:String):Dynamic
	{
		var rawJson = OpenFlAssets.getText(Paths.json(key, library)).trim();

		// Remove lixo no final do arquivo (arquivos mal-formados de alguns mods).
		while (!rawJson.endsWith("}"))
			rawJson = rawJson.substr(0, rawJson.length - 1);

		try
		{
			return Json.parse(rawJson);
		}
		catch (e)
		{
			Debug.logError("AN ERROR OCCURRED parsing a JSON file.");
			Debug.logError(e.message);
			return null;
		}
	}

	// ── Helpers de path ────────────────────────────────────────────────────────

	static public function getLibraryPath(file:String, library = "preload")
	{
		return (library == "preload" || library == "default")
			? getPreloadPath(file)
			: getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		return '$library:assets/$library/$file';
	}

	inline static function getPreloadPath(file:String)
	{
		return 'assets/$file';
	}

	// ── Atalhos de tipo ────────────────────────────────────────────────────────

	inline static public function file(file:String, ?library:String, type:AssetType = TEXT)
	{
		return getPath(file, type, library);
	}

	/**
	 * Lua modcharts — disponíveis somente em desktop (FEATURE_LUAMODCHART).
	 * No Android esses métodos compilam para null-safe stubs.
	 */
	#if FEATURE_LUAMODCHART
	inline static public function lua(key:String, ?library:String)
	{
		return getPath('data/$key.lua', TEXT, library);
	}

	inline static public function luaImage(key:String, ?library:String)
	{
		return getPath('data/$key.png', IMAGE, library);
	}
	#else
	inline static public function lua(key:String, ?library:String):String    return null;
	inline static public function luaImage(key:String, ?library:String):String return null;
	#end

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	// ── Áudio ──────────────────────────────────────────────────────────────────

	static public function sound(key:String, ?library:String)
	{
		return getPath('sounds/$key.$SOUND_EXT', SOUND, library);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String)
	{
		return getPath('music/$key.$SOUND_EXT', MUSIC, library);
	}

	inline static public function voices(song:String):Null<String>
	{
		var songLowercase = _normalizeSongName(song);
		var result = 'songs:assets/songs/${songLowercase}/Voices.$SOUND_EXT';
		return doesSoundAssetExist(result) ? result : null;
	}

	inline static public function inst(song:String):String
	{
		var songLowercase = _normalizeSongName(song);
		return 'songs:assets/songs/${songLowercase}/Inst.$SOUND_EXT';
	}

	/**
	 * Normaliza o nome de uma música para o padrão de pasta.
	 * Centralizado aqui para evitar duplicação entre voices() e inst().
	 */
	static function _normalizeSongName(song:String):String
	{
		var s = song.replace(" ", "-").toLowerCase();
		return switch (s)
		{
			case 'dad-battle':  'dadbattle';
			case 'philly-nice': 'philly';
			case 'm.i.l.f':     'milf';
			default:            s;
		};
	}

	// ── Listagem de songs ──────────────────────────────────────────────────────

	/**
	 * Retorna os nomes de todas as músicas disponíveis.
	 *
	 * Usa OpenFlAssets.list() — no Android isso lê o manifesto de assets
	 * dentro do APK sem extrair nada. Compatível com Polymod no desktop.
	 */
	static public function listSongsToCache():Array<String>
	{
		var soundAssets = OpenFlAssets.list(AssetType.MUSIC)
			.concat(OpenFlAssets.list(AssetType.SOUND));

		var songNames:Array<String> = [];

		for (sound in soundAssets)
		{
			var path = sound.split('/');
			path.reverse();

			var songName = path[1];

			if (path[2] != 'songs')
				continue;

			if (songNames.indexOf(songName) != -1)
				continue;

			songNames.push(songName);
		}

		return songNames;
	}

	// ── Checagens de existência ────────────────────────────────────────────────

	static public function doesSoundAssetExist(path:String):Bool
	{
		if (path == null || path == "")
			return false;
		return OpenFlAssets.exists(path, AssetType.SOUND)
			|| OpenFlAssets.exists(path, AssetType.MUSIC);
	}

	inline static public function doesTextAssetExist(path:String):Bool
	{
		return OpenFlAssets.exists(path, AssetType.TEXT);
	}

	// ── Imagens e atlas ────────────────────────────────────────────────────────

	inline static public function image(key:String, ?library:String)
	{
		return getPath('images/$key.png', IMAGE, library);
	}

	inline static public function font(key:String)
	{
		// Fontes são sempre embed=true no Project.xml, lidas via AssetManager.
		return 'assets/fonts/$key';
	}

	static public function getSparrowAtlas(key:String, ?library:String, ?isCharacter:Bool = false)
	{
		return isCharacter
			? FlxAtlasFrames.fromSparrow(
				loadImage('characters/$key', library),
				file('images/characters/$key.xml', library))
			: FlxAtlasFrames.fromSparrow(
				loadImage(key, library),
				file('images/$key.xml', library));
	}

	/** Senpai in Thorns usa PackerAtlas em vez de Sparrow. */
	inline static public function getPackerAtlas(key:String, ?library:String, ?isCharacter:Bool = false)
	{
		return isCharacter
			? FlxAtlasFrames.fromSpriteSheetPacker(
				loadImage('characters/$key', library),
				file('images/characters/$key.txt', library))
			: FlxAtlasFrames.fromSpriteSheetPacker(
				loadImage(key, library),
				file('images/$key.txt', library));
	}
}