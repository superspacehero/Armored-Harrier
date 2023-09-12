using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.InputSystem;
using Pathfinding;
using NaughtyAttributes;

public class ThingInput : UnsavedThing
{
    public bool isPlayer = true;

    public PlayerInput playerInput
    {
        get
        {
            if (_playerInput == null)
                TryGetComponent(out _playerInput);

            return _playerInput;
        }
    }
    private PlayerInput _playerInput;

    #region Vibration

    private Gamepad gamepad
    {
        get
        {
            if (_gamepad == null && !_hasCheckedForGamepad)
            {
                _hasCheckedForGamepad = true;
                if (playerInput != null)
                    _gamepad = playerInput.devices.FirstOrDefault(device => device is Gamepad) as Gamepad;
            }

            return _gamepad;
        }
    }
    private Gamepad _gamepad;
    private bool _hasCheckedForGamepad = false;

    private List<AudioSource> audioSources = new List<AudioSource>();
    private bool isVibrationCoroutineRunning = false;

    public void AddAudioSourceForVibration(AudioSource source)
    {
        if (source == null || audioSources.Contains(source)) return;

        audioSources.Add(source);

        if (!isVibrationCoroutineRunning)
        {
            StartCoroutine(VibrateBasedOnAudio());
        }
    }

    private IEnumerator VibrateBasedOnAudio()
    {
        isVibrationCoroutineRunning = true;

        while (audioSources.Count > 0)
        {
            float cumulativeVibration = 0;

            for (int i = audioSources.Count - 1; i >= 0; i--)
            {
                if (audioSources[i] == null || !audioSources[i].isPlaying)
                {
                    audioSources.RemoveAt(i);
                }
                else
                {
                    cumulativeVibration += GetCurrentAudioVolume(audioSources[i]);
                }
            }

            cumulativeVibration = Mathf.Clamp01(cumulativeVibration);
            gamepad?.SetMotorSpeeds(cumulativeVibration, cumulativeVibration);

            yield return null; // wait for the next frame
        }

        isVibrationCoroutineRunning = false;
    }

    private float GetCurrentAudioVolume(AudioSource source)
    {
        float[] data = new float[256];
        source.GetOutputData(data, 0);
        float a = 0;
        foreach (float s in data)
        {
            a += Mathf.Abs(s);
        }
        return a / 256.0f;
    }

    #endregion

    #region AI Variables

    private Coroutine _actionCoroutine;
    [SerializeField] private List<GameThing> _targets = new List<GameThing>();
    private int _currentTargetIndex = 0;

    public bool canControl
    {
        get => _canControl;
        set
        {
            _canControl = value;
        }
    }
    [SerializeField] private bool _canControl = false;

    enum AIState
    {
        ChoosingAction,
        Idling,
        Moving,
        Attacking,
        Healing,
        Fleeing,
        EndingTurn
    }

    [SerializeField] private float _actionDelay = 1f;

    private void GetPathToCurrentTarget(CharacterThing thing, out List<GraphNode> path, int maxDistance = 0)
    {
        path = Nodes.GetPathToNode(thing.transform.position, _targets[_currentTargetIndex].transform.position, maxDistance);
        // Nodes.instance.DisplayNodes(path);
    }

    #endregion

    void OnEnable()
    {
        GameManager.AddPlayer(this);
    }

    void OnDisable()
    {
        GameManager.RemovePlayer(this);
    }

    public Vector2 movement
    {
        get => _movement;
        set
        {
            _movement = value;

            foreach (Inventory.ThingSlot slot in inventory.thingSlots)
                if (slot.thing)
                    slot.thing.Move(_movement);
        }
    }
    private Vector2 _movement;

    public Vector2 aim
    {
        get => _aim;
        set
        {
            _aim = value;

            foreach (Inventory.ThingSlot slot in inventory.thingSlots)
                if (slot.thing)
                    slot.thing.Aim(_aim);
        }
    }
    private Vector2 _aim;

    public bool leftTriggerAction
    {
        get => _leftTriggerAction;
        set
        {
            _leftTriggerAction = value;

            foreach (Inventory.ThingSlot slot in inventory.thingSlots)
                if (slot.thing)
                    slot.thing.LeftTriggerAction(_leftTriggerAction);
        }
    }
    private bool _leftTriggerAction;

    public bool rightTriggerAction
    {
        get => _rightTriggerAction;
        set
        {
            _rightTriggerAction = value;

            foreach (Inventory.ThingSlot slot in inventory.thingSlots)
                if (slot.thing)
                    slot.thing.RightTriggerAction(_rightTriggerAction);
        }
    }
    private bool _rightTriggerAction;

    public bool primaryAction
    {
        get => _primaryAction;
        set
        {
            _primaryAction = value;

            foreach (Inventory.ThingSlot slot in inventory.thingSlots)
                if (slot.thing)
                    slot.thing.PrimaryAction(_primaryAction);
        }
    }
    private bool _primaryAction;

    public bool secondaryAction
    {
        get => _secondaryAction;
        set
        {
            _secondaryAction = value;

            foreach (Inventory.ThingSlot slot in inventory.thingSlots)
                if (slot.thing)
                    slot.thing.SecondaryAction(_secondaryAction);

            if (canControl && _secondaryAction)
                Menu.currentMenuOption?.PreviousMenu();
        }
    }
    private bool _secondaryAction;

    public bool tertiaryAction
    {
        get => _tertiaryAction;
        set
        {
            _tertiaryAction = value;

            foreach (Inventory.ThingSlot slot in inventory.thingSlots)
                if (slot.thing)
                    slot.thing.TertiaryAction(_tertiaryAction);
        }
    }
    private bool _tertiaryAction;

    public bool quaternaryAction
    {
        get => _quaternaryAction;
        set
        {
            _quaternaryAction = value;

            foreach (Inventory.ThingSlot slot in inventory.thingSlots)
                if (slot.thing)
                    slot.thing.QuaternaryAction(_quaternaryAction);
        }
    }
    private bool _quaternaryAction;

    public bool leftAction
    {
        get => _leftAction;
        set
        {
            _leftAction = value;

            foreach (Inventory.ThingSlot slot in inventory.thingSlots)
                if (slot.thing)
                    slot.thing.LeftAction(_leftAction);
        }
    }
    private bool _leftAction;

    public bool rightAction
    {
        get => _rightAction;
        set
        {
            _rightAction = value;

            foreach (Inventory.ThingSlot slot in inventory.thingSlots)
                if (slot.thing)
                    slot.thing.RightAction(_rightAction);
        }
    }
    private bool _rightAction;

    public bool pause
    {
        get => _pause;
        set
        {
            _pause = value;

            foreach (Inventory.ThingSlot slot in inventory.thingSlots)
                if (slot.thing && slot.thing is CharacterThing)
                    (slot.thing as CharacterThing).Pause();
        }
    }
    private bool _pause;

    public void OnMove(InputValue value)
    {
        movement = value.Get<Vector2>();
    }

    public void OnAim(InputValue value)
    {
        aim = value.Get<Vector2>();
    }

    public void OnButton1(InputValue value)
    {
        primaryAction = value.isPressed;
    }

    public void OnButton2(InputValue value)
    {
        secondaryAction = value.isPressed;
    }

    public void OnButton3(InputValue value)
    {
        tertiaryAction = value.isPressed;
    }

    public void OnButton4(InputValue value)
    {
        quaternaryAction = value.isPressed;
    }

    public void OnButtonLeft(InputValue value)
    {
        leftAction = value.isPressed;
    }

    public void OnButtonRight(InputValue value)
    {
        rightAction = value.isPressed;
    }

    public void OnTriggerLeft(InputValue value)
    {
        leftTriggerAction = value.isPressed;
    }

    public void OnTriggerRight(InputValue value)
    {
        rightTriggerAction = value.isPressed;
    }

    public void OnPause(InputValue value)
    {
        pause = value.isPressed;
    }
}
