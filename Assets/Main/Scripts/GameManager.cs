using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.UI;
using NaughtyAttributes;

public enum GameMode
{
    Other,
    Play,
    Make
}

public class GameManager : MonoBehaviour
{
    #region Singleton

    public static GameManager instance
    {
        get
        {
            if (_instance == null)
                _instance = FindObjectOfType<GameManager>();

            return _instance;
        }
    }
    private static GameManager _instance;

    #endregion

    #region Game variables

    public static GameMode gameMode = GameMode.Other;

    #endregion

    #region Level

    public static string levelString;

    #endregion

    #region Players

    public GameObject characterPrefab;

    public struct PlayerAndCharacter
    {
        // The device that the player is using
        public InputDevice player;

        // The character that the player is controlling
        public CharacterThing.CharacterInfo character;

        // The team that the player is on
        public int team;

        public PlayerAndCharacter(PlayerInput playerInput, CharacterThing.CharacterInfo character, int team = 0)
        {
            // If the player input is null, then the player is a CPU
            player = (playerInput != null) ? playerInput.devices[0] : null;
            this.character = character;
            this.team = team;
        }
    }
    public static List<PlayerAndCharacter> players = new List<PlayerAndCharacter>();

    public List<ThingInput> inputs = new List<ThingInput>();
    public static void AddPlayer(ThingInput player)
    {
        instance?.inputs.Add(player);
    }

    public static void RemovePlayer(ThingInput player)
    {
        instance?.inputs.Remove(player);
    }

    public float changeCharacterDelay = 1f;

    #endregion

    #region Things

    [SerializeField] private General.ObjectPool<UnityEngine.VFX.VisualEffect> damagePool, footstepPool;
    [SerializeField] private General.ObjectPool<NumberVisual> damageIndicatorPool, healIndicatorPool;

    public void DamageEffect(int damageAmount, GameThing thing, Vector3 position)
    {
        // Set up the damage indicator
        NumberVisual damageIndicator = damageIndicatorPool.GetObjectFromPool(Vector3.zero);
        damageIndicator.number = damageAmount;
        damageIndicator.followWorldPosition.target = thing;

        // Set up the visual effect
        UnityEngine.VFX.VisualEffect damageEffect = damagePool.GetObjectFromPool(position);
        damageEffect.SetInt("Damage", damageAmount);
        damageEffect.Play();
    }

    public void HealEffect(int healAmount, GameThing thing)
    {
        // Set up the heal indicator
        NumberVisual healIndicator = healIndicatorPool.GetObjectFromPool(Vector3.zero);
        healIndicator.number = healAmount;
        healIndicator.followWorldPosition.target = thing;
    }

    public void FootstepEffect(Vector3 position)
    {
        UnityEngine.VFX.VisualEffect footstepEffect = footstepPool.GetObjectFromPool(position);
        footstepEffect.SetInt("Smoke Count", 1);
        footstepEffect.Play();
    }

    public void LandingEffect(Vector3 position)
    {
        UnityEngine.VFX.VisualEffect landingEffect = footstepPool.GetObjectFromPool(position);
        landingEffect.ResetOverride("Smoke Count");
        landingEffect.Play();
    }

    [SerializeField] private General.ObjectPool<ThingDisplay> thingDisplayPool, thingDisplayDescriptionPool;
    public static ThingDisplay GetThingDisplay(Transform parent = null, bool description = false)
    {
        ThingDisplay thingDisplay = null;

        if (description)
        {
            thingDisplay = instance.thingDisplayDescriptionPool.GetObjectFromPool(Vector3.zero);
            thingDisplay.transform.SetParent(parent, false);
            return thingDisplay;
        }

        thingDisplay = instance.thingDisplayPool.GetObjectFromPool(Vector3.zero);
        thingDisplay.transform.SetParent(parent, false);
        return thingDisplay;
    }

    #region Characters

    #endregion

    #endregion

    public static void ResetInputModule()
    {
        if (instance == null)
            return;

        instance.inputModule.enabled = false;
        instance.inputModule.enabled = true;
    }

    private InputSystemUIInputModule inputModule
    {
        get
        {
            if (_inputModule == null)
                _inputModule = GetComponentInChildren<InputSystemUIInputModule>();
            return _inputModule;
        }
    }
    private InputSystemUIInputModule _inputModule;

    private PlayerInputManager playerInputManager
    {
        get
        {
            if (_playerInputManager == null)
                _playerInputManager = GetComponentInChildren<PlayerInputManager>();
            return _playerInputManager;
        }
    }
    private PlayerInputManager _playerInputManager;
}
