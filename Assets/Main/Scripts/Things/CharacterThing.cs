using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using NaughtyAttributes;

[AddComponentMenu("Game Things/Character Thing")]
public class CharacterThing : GameThing
{
    // CharacterThings are a subclass of GameThings that represent characters in the game.

    public override string thingType
    {
        get => "Character";
    }

    // The character's input
    public ThingInput input;

    // The character's portrait
    public Sprite thingPortrait;

    // The list of character parts
    public CharacterPartList characterPartList;

    // The character's energy
    public float energy
    {
        get
        {
            return _energy;
        }

        set
        {
            _energy = value;
            if (_energy <= 0f)
            {
                _energy = 0f;
                canUseEnergy = false;
            }
            else if (_energy >= maxEnergy)
            {
                _energy = maxEnergy;
                canUseEnergy = true;
            }

            onEnergyChanged?.Invoke(_energy);
        }
    }
    private float _energy;
    public float maxEnergy = 100f;
    public bool canUseEnergy { get; private set; } = true;
    public float energyConsumptionRate = 0f;
    public System.Action<float> onEnergyChanged;

    /// <summary>
    /// This function is called every fixed framerate frame, if the MonoBehaviour is enabled.
    /// </summary>
    void FixedUpdate()
    {
        if (energyConsumptionRate > 0f)
            energy -= energyConsumptionRate * Time.fixedDeltaTime;
        else if (energy < maxEnergy)
            energy += -energyConsumptionRate * Time.fixedDeltaTime;
    }

    public struct CharacterInfo
    {
        public string name, portrait;
        public int team;
        public int value;
        public Inventory inventory;
        public GameThingVariables baseVariables;
        public List<CharacterPartThing.CharacterPartInfo> characterParts;

        public string ToString(bool isNPC = false)
        {
            CharacterInfo characterInfo = this;
            if (isNPC)
                characterInfo.portrait = "";

            string info = JsonUtility.ToJson(characterInfo);

            // Replace all double quotes with escaped double quotes
            if (isNPC)
                info = info.Replace("\"", "\\\"");

            return info;
        }

        public static CharacterInfo FromString(string json)
        {
            // Replace all escaped double quotes with double quotes
            json = json.Replace("\\\"", "\"");

            return JsonUtility.FromJson<CharacterInfo>(json);
        }

        private static void CheckCharacterDirectory()
        {
            if (!System.IO.Directory.Exists(Application.persistentDataPath + "/Characters/"))
                System.IO.Directory.CreateDirectory(Application.persistentDataPath + "/Characters/");
        }

        public CharacterInfo LoadCharacter(string characterName, string characterCategory = "Player")
        {
            CheckCharacterDirectory();

            if (System.IO.File.Exists(Application.persistentDataPath + $"/Characters/{characterCategory}_{characterName}.json"))
            {
                string json = System.IO.File.ReadAllText(Application.persistentDataPath + $"/Characters/{characterCategory}_{characterName}.json");
                return FromString(json);
            }
            else
            {
                Debug.LogError($"Character {characterName} does not exist");
                return new CharacterInfo();
            }
        }

        public void SaveCharacter(string characterName, string characterCategory = "Player")
        {
            CheckCharacterDirectory();

            string json = ToString();

            System.IO.File.WriteAllText(Application.persistentDataPath + $"/Characters/{characterCategory}_{LoadCharacters(characterCategory).Count + 1}_{characterName}.json", json);
        }

        public static List<CharacterInfo> LoadCharacters(string characterCategory = "Player")
        {
            CheckCharacterDirectory();

            List<CharacterInfo> characters = new List<CharacterInfo>();

            foreach (string characterFile in System.IO.Directory.GetFiles(Application.persistentDataPath + $"/Characters/", $"{characterCategory}_*.json"))
            {
                string json = System.IO.File.ReadAllText(characterFile);
                characters.Add(FromString(json));
            }

            return characters;
        }

        public static void DeleteCharacter(string characterName, string characterCategory = "Player")
        {
            CheckCharacterDirectory();

            System.IO.File.Delete(Application.persistentDataPath + $"/Characters/{characterCategory}_{characterName}.json");
        }

        public CharacterInfo(string name, string portrait, int team, int value, Inventory inventory, GameThingVariables baseVariables, List<CharacterPartThing.CharacterPartInfo> characterParts)
        {
            this.name = name;
            this.portrait = portrait;
            this.team = team;
            this.value = value;
            this.inventory = inventory;
            this.baseVariables = baseVariables;
            this.characterParts = characterParts;
        }

        public CharacterInfo(string name, Sprite portrait, int team, int value, Inventory inventory, GameThingVariables baseVariables, List<CharacterPartThing.CharacterPartInfo> characterParts)
        {
            this.name = name;
            this.portrait = General.SpriteToString(portrait);
            this.team = team;
            this.value = value;
            this.inventory = inventory;
            this.baseVariables = baseVariables;
            this.characterParts = characterParts;
        }

        // Operator to check if the character equals another character
        public static bool Equals(CharacterInfo characterInfo1, CharacterInfo characterInfo2)
        {
            return characterInfo1.name == characterInfo2.name &&
                characterInfo1.portrait == characterInfo2.portrait &&
                characterInfo1.value == characterInfo2.value &&
                characterInfo1.inventory == characterInfo2.inventory &&
                characterInfo1.baseVariables.Equals(characterInfo2.baseVariables) &&
                characterInfo1.characterParts == characterInfo2.characterParts;
        }
    }
    public CharacterInfo characterInfo
    {
        get
        {
            return new CharacterInfo()
            {
                name = thingName,
                portrait = General.SpriteToString(thingPortrait),
                team = characterTeam,
                value = thingValue,
                inventory = inventory,
                baseVariables = this.baseVariables,
                characterParts = this.characterParts
            };
        }

        set
        {
            thingName = value.name;
            thingPortrait = General.StringToSprite(value.portrait);
            characterTeam = value.team;

            thingValue = value.value;

            AddInventory();

            baseVariables = value.baseVariables;

            characterParts = value.characterParts;
        }
    }

    // Team that the character belongs to
    public int characterTeam;

    #region Controlling Characters

    // Movement controller for moving the character
    public MovementController movementController
    {
        get
        {
            if (_characterController == null)
                _characterController = GetComponentInChildren<MovementController>();
            return _characterController;
        }
    }
    private MovementController _characterController;

    // Method to attach or detach this character thing to a user
    public override void Use(GameThing user)
    {
        if (user != null)
        {
            if (user.GetAttachedThing() == this)
                user.DetachThing();
            else
                user.AttachThing(this);
        }
    }

    // The character's camera
    public GameplayCamera gameplayCamera
    {
        get
        {
            if (_gameplayCamera == null)
                _gameplayCamera = GetComponentInChildren<GameplayCamera>();

            return _gameplayCamera;
        }
    }
    private GameplayCamera _gameplayCamera;

    // Method to move character
    public override void Move(Vector2 direction)
    {
        if (!(movementController.canControl > 0 && interaction != null && interaction.interacting))
        {

            if (movementController != null && movementController.canControl > MovementController.ControlLevel.MovementOnly)
                movementController.movementInput = direction;
        }
        else
            if (movementController != null && movementController.canControl > MovementController.ControlLevel.MovementOnly)
            movementController.movementInput = Vector2.zero;

        base.Move(direction);
    }

    // Method to aim for character
    public override void Aim(Vector2 direction)
    {
        if (movementController.canControl > MovementController.ControlLevel.MovementOnly)
            gameplayCamera.Rotate(new Vector3(direction.y, direction.x, 0f));
    }

    // Method to perform primary action on character
    public override void PrimaryAction(bool pressed)
    {
        if (!(movementController.canControl > 0 && interaction != null && interaction.PrimaryAction != null && interaction.canInteract))
        {

            if (movementController != null && movementController.canControl > MovementController.ControlLevel.MovementOnly)
                movementController.jumpInput = pressed;
        }

        base.PrimaryAction(pressed);
    }

    // Method to perform secondary action on character
    public override void SecondaryAction(bool pressed)
    {
        if (!(movementController.canControl > 0 && interaction != null && interaction.SecondaryAction != null && interaction.canInteract))
        {
        }

        base.SecondaryAction(pressed);
    }

    // Method to perform tertiary action on character
    public override void TertiaryAction(bool pressed)
    {
        if (!(movementController.canControl > 0 && interaction != null && interaction.canInteract))
        {
        }

        base.TertiaryAction(pressed);
    }

    // Method to perform quaternary action on character
    public override void QuaternaryAction(bool pressed)
    {
        if (!(movementController.canControl > 0 && interaction != null && interaction.canInteract))
        {
        }

        base.QuaternaryAction(pressed);
    }

    // Method to perform left action on character
    public override void LeftAction(bool pressed)
    {
        if (!(movementController.canControl > 0 && interaction != null && interaction.canInteract))
        {
        }

        base.LeftAction(pressed);
    }

    // Method to perform right action on character
    public override void RightAction(bool pressed)
    {
        if (!(movementController.canControl > 0 && interaction != null && interaction.canInteract))
        {
        }

        base.RightAction(pressed);
    }

    // Method to perform left trigger action on character
    public override void LeftTriggerAction(bool pressed)
    {
        if (!(movementController.canControl > 0 && interaction != null && interaction.canInteract))
        {
        }

        base.LeftTriggerAction(pressed);
    }

    // Method to perform right trigger action on character
    public override void RightTriggerAction(bool pressed)
    {
        if (!(movementController.canControl > 0 && interaction != null && interaction.canInteract))
        {
        }

        base.RightTriggerAction(pressed);
    }

    // Method to pause the game
    public void Pause()
    {

    }

    #endregion

    #region Character Assembly

    // List of character part prefabs used to assemble the character
    [UnityEngine.Serialization.FormerlySerializedAs("characterPartPrefabs")]
    public List<CharacterPartThing.CharacterPartInfo> characterParts = new List<CharacterPartThing.CharacterPartInfo>();
    // List of character parts that make up the character
    public List<CharacterPartThing> parts = new List<CharacterPartThing>();
    protected List<CharacterPartThing> addedParts = new List<CharacterPartThing>();
    [Foldout("Variables")] public GameThingVariables baseVariables = new GameThingVariables();

    // Base inventory slot for character
    [SerializeField] protected Inventory.ThingSlot characterBase;

    // Method to get all the character part slots, including the base slot
    public List<Inventory.ThingSlot> GetCharacterPartSlots()
    {
        List<Inventory.ThingSlot> slots = new List<Inventory.ThingSlot>();

        slots.Add(characterBase);

        foreach (CharacterPartThing part in parts)
        {
            if (part.TryGetComponent(out Inventory inventory))
            {
                foreach (Inventory.ThingSlot slot in inventory.thingSlots)
                {
                    slots.Add(slot);
                }
            }
        }

        return slots;
    }

    // Method to attach parts to a character part
    void AttachPartsToPart(CharacterPartThing part)
    {
        if (part.TryGetComponent(out Inventory inventory))
        {
            foreach (Inventory.ThingSlot slot in inventory.thingSlots)
            {
                AttachPartToSlot(slot);
            }
        }
    }

    // Method to attach a character part to a slot
    void AttachPartToSlot(Inventory.ThingSlot slot)
    {
        foreach (CharacterPartThing part in parts)
        {
            if ((part.thingType == slot.thingType || part.thingSubType == slot.thingType) && !addedParts.Contains(part))
            {
                slot.AddThing(part);
                addedParts.Add(part);
                variables += part.variables;

                part.SetColors();
                part.gameObject.SetActive(true);
                if (movementController != null)
                    part.SetAnimationClips(movementController.anim);

                AttachPartsToPart(part);

                break;
            }
        }
    }

    // Method to assemble the character
    [Button]
    public void AssembleCharacter()
    {
        gameObject.name = thingName;

        // Destroy all children of the characterBase first.
        for (int i = characterBase.transform.childCount - 1; i >= 0; i--)
        {
#if UNITY_EDITOR
            DestroyImmediate(characterBase.transform.GetChild(i).gameObject);
#else
            Destroy(characterBase.transform.GetChild(i).gameObject);
#endif
        }

        parts.Clear();

        if (variables.variables != null)
            variables.variables.Clear();
        variables += baseVariables;

        movementController.ResetAnimator();

        foreach (CharacterPartThing.CharacterPartInfo characterPart in characterParts)
        {
            if (string.IsNullOrEmpty(characterPart.prefabName))
                continue;

            // Debug.Log("Instantiating " + characterPart.prefabName);

            if (CharacterPartThing.Instantiate(out CharacterPartThing characterPartThing, characterPartList, characterPart, characterBase.transform))
            {
                parts.Add(characterPartThing);

                if (characterPartThing.TryGetComponent(out CapsuleCollider capsuleCollider) && TryGetComponent(out CMF.Mover mover))
                {
                    capsuleCollider.enabled = false;
                    mover.SetColliderThickness(capsuleCollider.radius * 2);
                    mover.SetColliderHeight(capsuleCollider.height);
                }

                characterPartThing.gameObject.SetActive(false);
            }
        }

        AttachPartToSlot(characterBase);

        // Reset the animator
        if (TryGetComponent(out Animator animator))
        {
            RuntimeAnimatorController animatorController = animator.runtimeAnimatorController;
            animator.runtimeAnimatorController = null;
            animator.runtimeAnimatorController = animatorController;
        }

        // Set the speed of the movement controller
        if (movementController != null)
            movementController.movementSpeed = variables.GetVariable("speed");

        // Set the energy of the character
        maxEnergy = variables.GetVariable("energy");
        energy = maxEnergy;
    }

    // Method to convert the character to a JSON string
    public string ToString(bool isNPC = false)
    {
        return characterInfo.ToString(isNPC);
    }

    // Method to save the character to a file
    public void SaveCharacter(string characterCategory = "Player")
    {
        characterInfo.SaveCharacter(thingName, characterCategory);
    }

    // Method to create the character from a JSON string
    public void FromString(string characterSaveData)
    {
        characterInfo = JsonUtility.FromJson<CharacterInfo>(characterSaveData);

        AssembleCharacter();
    }

    // Method to load the character from a file
    public void LoadCharacter(string characterName, string characterCategory = "Player")
    {
        characterInfo = characterInfo.LoadCharacter(characterName, characterCategory);

        AssembleCharacter();
    }

    #endregion

    /// <summary>
    /// Start is called on the frame when a script is enabled just before
    /// any of the Update methods is called the first time.
    /// </summary>
    protected override void Start()
    {
        AssembleCharacter();

        gameplayCamera.SetCameraObject(this, 1f, true);

        base.Start();
    }

    /// <summary>
    /// This function is called when the behaviour becomes disabled or inactive.
    /// </summary>
    void OnDisable()
    {
        UnoccupyCurrentNode();
    }

    /// <summary>
    /// This function is called when the MonoBehaviour will be destroyed.
    /// </summary>
    protected override void OnDestroy()
    {
        base.OnDestroy();

        UnoccupyCurrentNode();
    }
}