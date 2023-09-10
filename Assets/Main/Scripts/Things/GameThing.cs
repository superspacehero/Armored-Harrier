using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using NaughtyAttributes;
using Pathfinding;

[AddComponentMenu("Game Things/Game Thing")]
public class GameThing : MonoBehaviour
{
    // GameThings are a base class for all interactables and collectibles in the game.
    // They have a name, a description, an icon, and a value.
    // Their value is primarily used for determining how much they are worth when sold,
    // but can also be used for other things, such as the number a die lands on.

    // They also have a thingType, which is a string used to determine what type of thing they are,
    // and an attachedThing, which is a reference to another GameThing that is attached to this one.
    // This can be used to control an attached GameThing, or to pass information between two GameThings.

    // At their core, their primary function is to be used,
    // which is handled by the Use() function.

    protected void SetMaxHealth()
    {
        if (variables.GetVariable("health") > 0 && variables.GetVariable("maxHealth") <= 0)
            variables.SetVariable("maxHealth", variables.GetVariable("health"));
    }

    // Start is called before the first frame update
    protected virtual void Start()
    {
        SetMaxHealth();
    }

    /// <summary>
    /// This function is called when the MonoBehaviour will be destroyed.
    /// </summary>
    [ExecuteInEditMode]
    protected virtual void OnDestroy()
    {
    }

    public GameObject thingPrefab;
#if UNITY_EDITOR
    [Button, HideIf("hasPrefab")]
    protected void GetPrefab()
    {
        thingPrefab = gameObject;
    }

    protected bool hasPrefab { get => thingPrefab != null; }
#endif

    public virtual string thingName
    {
        get => _thingName;
        set => _thingName = value;
    }
    [SerializeField, UnityEngine.Serialization.FormerlySerializedAs("thingName")] protected string _thingName;

    public bool properNoun = false;

    public string thingDescription;

    public virtual Sprite thingIcon
    {
        get
        {
            if (_thingIcon == null)
                if (TryGetComponent(out SpriteRenderer spriteRenderer))
                    _thingIcon = spriteRenderer.sprite;
                else
                    Debug.LogWarning($"GameThing {name} has no icon.");

            return _thingIcon;
        }
    }
    [SerializeField] protected Sprite _thingIcon;

    public virtual GraphNode currentNode
    {
        get
        {
            if (_currentNode == null)
            {
                _currentNode = AstarPath.active.GetNearest(transform.position).node;
            }

            return _currentNode;
        }
        set
        {
            if (canOccupyCurrentNode)
            {
                UnoccupyNode(_currentNode);
                _currentNode = value;
                OccupyNode(_currentNode);
            }
            else
            {
                _currentNode = value;
            }
        }
    }

    protected GraphNode _currentNode;

    public bool canOccupyCurrentNode = true;

    public void OccupyCurrentNode()
    {
        canOccupyCurrentNode = true;

        currentNode = AstarPath.active.GetNearest(position).node;
    }

    public void UnoccupyCurrentNode(bool overrideCanOccupyCurrentNode = false)
    {
        if (overrideCanOccupyCurrentNode)
            canOccupyCurrentNode = true;

        currentNode = null;

        if (overrideCanOccupyCurrentNode)
            canOccupyCurrentNode = false;
    }

    private void OccupyNode(GraphNode node)
    {
        if (node != null)
        {
            Nodes.OccupyNode(node, this);
        }
    }

    private void UnoccupyNode(GraphNode node)
    {
        if (node != null)
        {
            Nodes.UnoccupyNode(node, this);
        }
    }

    public virtual Vector3 position
    {
        get => currentNode != null ? (Vector3)currentNode.position : transform.position;
        set
        {
            GraphNode nearestNode = AstarPath.active.GetNearest(value).node;
            currentNode = nearestNode;
            transform.position = value;
        }
    }

    public int thingValue;
    [SerializeField, Foldout("Attached Things")] protected Inventory.ThingSlot attachedThing;

    public virtual string thingType
    {
        get => "Game";
    }

    public virtual string thingSubType
    {
        get => "";
    }

    // Method to convert the GameThing to a JSON string
    public string ToJson()
    {
        string jsonString = JsonUtility.ToJson(this);
        return jsonString;
    }

    [Button]
    public void PrintJson()
    {
        Debug.Log(ToJson());
    }

    // Method to convert a JSON string to a GameThing
    public static GameThing FromJson(string jsonString)
    {
        GameThing gameThing = JsonUtility.FromJson<GameThing>(jsonString);
        return gameThing;
    }

    // This function has a variety of uses, depending on the GameThing subclass, which include:
    // - Item GameThings on the floor, which lets them be picked up by the user;
    // - Consumable item GameThings, which leaves behind one, some, or no other GameThings on use, depending on the item;
    // - Equipment item GameThings, which can be equipped and unequipped, and which change stats on the character equipping them;
    // - Character GameThings, which, when used by another character, allow the user to take control of the target character
    //   (used for player characters, NPCs, and objects that can be directly controlled);
    // - Mechanism Trigger and Mechanism GameThings, the former of which can be used to toggle, activate, or deactivate the latter
    //   (used for doors, switches, and other objects that can be interacted with in a variety of ways);

    public virtual void Use(GameThing user)
    {
        // This is the base Use() function for GameThings.
        // It does nothing, and is overridden by subclasses.
    }

    public void AttachThing(GameThing thing)
    {
        attachedThing.AddThing(thing);
    }

    public void DetachThing()
    {
        attachedThing.RemoveThing();
    }

    public GameThing GetAttachedThing()
    {
        return attachedThing.thing;
    }

    private bool hasInventory { get => inventory != null; }

    [Button, HideIf("hasInventory")]
    protected void AddInventory()
    {
        if (inventory == null)
            _inventory = gameObject.AddComponent<Inventory>();
    }

    // Inventory for the thing
    public Inventory inventory
    {
        get
        {
            if (_inventory == null)
                TryGetComponent(out _inventory);
            return _inventory;
        }

        set
        {
            _inventory = value;
        }
    }
    private Inventory _inventory;

    #region Interactions

    // Interaction list for the thing
    public Interactions interactionList
    {
        get
        {
            if (_interactionList == null)
            {
                _interactionList = GetComponentInChildren<Interactions>();
            }
            return _interactionList;
        }
    }
    private Interactions _interactionList;

    /// <summary>
    /// OnCollisionEnter is called when this collider/rigidbody has begun
    /// touching another rigidbody/collider.
    /// </summary>
    /// <param name="other">The Collision data associated with this collision.</param>
    void OnCollisionEnter(Collision other)
    {
        interactionList?.OnCollisionEnter(other);
    }

    /// <summary>
    /// OnCollisionExit is called when this collider/rigidbody has
    /// stopped touching another rigidbody/collider.
    /// </summary>
    /// <param name="other">The Collision data associated with this collision.</param>
    void OnCollisionExit(Collision other)
    {
        interactionList?.OnCollisionExit(other);
    }

    /// <summary>
    /// OnTriggerEnter is called when the Collider other enters the trigger.
    /// </summary>
    /// <param name="other">The other Collider involved in this collision.</param>
    void OnTriggerEnter(Collider other)
    {
        interactionList?.OnTriggerEnter(other);
    }

    /// <summary>
    /// OnTriggerExit is called when the Collider other has stopped touching the trigger.
    /// </summary>
    /// <param name="other">The other Collider involved in this collision.</param>
    void OnTriggerExit(Collider other)
    {
        interactionList?.OnTriggerExit(other);
    }

    #endregion

    public Transform thingTop
    {
        get
        {
            // If the thingTop is null, check if any of its descendants have the tag "ThingTop".
            if (_thingTop == null)
            {
                _thingTop = General.FindDescendantWithTag(transform, "ThingTop");

                // If the thingTop is still null, set it to the transform of the GameThing.
                if (_thingTop == null)
                {
                    Debug.LogWarning($"No thingTop found for {name}. Setting to transform.");
                    _thingTop = transform;
                }
            }
            return _thingTop;
        }
    }

    private Transform _thingTop;

    public GameThingVariables variables = new GameThingVariables();

    [System.Serializable]
    public class GameThingVariables
    {
        // A list of variables, each with a name and a value.
        public List<Variable> variables = new List<Variable>();

        // A class to represent a single variable, with a name and a value.
        [System.Serializable]
        public class Variable
        {
            // The name of the variable.
            [NaughtyAttributes.BoxGroup("Variable")] public string name;
            // The value of the variable.
            [NaughtyAttributes.BoxGroup("Variable")] public int value;

            // Constructor for the Variable class.
            public Variable(string name, int value)
            {
                this.name = name;
                this.value = value;
            }
        }

        // Get the value of a variable.
        public int GetVariable(string name)
        {
            // If the variable list is null, return 0.
            if (variables == null)
                return 0;

            // Find the variable with the given name.
            Variable variable = variables.Find(v => v.name == name);
            // If the variable is not found, return 0.
            if (variable == null)
                return 0;

            // Return the value of the variable.
            return variable.value;
        }

        // Set the value of a variable.
        public void SetVariable(string name, int value)
        {
            // Find the index of the variable with the given name.
            int index = variables.FindIndex(v => v.name == name);
            if (index != -1)
            {
                if (name == "health")
                {
                    // Check if the new health value is greater than the max health value
                    int maxHealth = GetVariable("maxHealth");
                    if (value > maxHealth)
                    {
                        value = maxHealth;
                    }
                }

                variables[index].value = value; // Update the value directly since it's a class now
            }
            else
            {
                variables.Add(new Variable(name, value));
            }

            // Debug.Log($"Set variable {name} to {value}.");
        }

        // Add a value to a variable.
        public void AddToVariable(string name, int value)
        {
            SetVariable(name, GetVariable(name) + value);
        }

        // Operator to add two instances of GameThingVariables together.
        public static GameThingVariables operator +(GameThingVariables a, GameThingVariables b)
        {
            GameThingVariables result = new GameThingVariables();

            foreach (Variable variable in a.variables)
            {
                Variable otherVariable = b.variables.Find(v => v.name == variable.name);
                if (otherVariable != null)
                {
                    result.variables.Add(new Variable(variable.name, variable.value + otherVariable.value));
                }
                else
                {
                    result.variables.Add(new Variable(variable.name, variable.value));
                }
            }

            foreach (Variable variable in b.variables)
            {
                if (!result.variables.Exists(v => v.name == variable.name))
                {
                    result.variables.Add(new Variable(variable.name, variable.value));
                }
            }

            return result;
        }

        // Operator to compare two instances of GameThingVariables.
        public override bool Equals(object obj)
        {
            if (!(obj is GameThingVariables other))
                return false;

            if (variables.Count != other.variables.Count)
                return false;

            foreach (Variable variable in variables)
            {
                Variable otherVariable = other.variables.Find(v => v.name == variable.name);
                if (otherVariable == null || otherVariable.value != variable.value)
                    return false;
            }

            return true;
        }

        public override int GetHashCode()
        {
            // A simple approach to generating a hash code. This could be enhanced further.
            return variables.Select(v => v.name.GetHashCode() ^ v.value.GetHashCode()).Aggregate(0, (a, b) => a ^ b);
        }

    }

    #region Colors

    protected virtual bool useColor { get; set; }

    // A material property block, used to change the colors of the Red, Green, and Blue channels of the character part's sprite(s).
    private MaterialPropertyBlock materialPropertyBlock
    {
        get
        {
            if (_materialPropertyBlock == null)
            {
                _materialPropertyBlock = new MaterialPropertyBlock();
            }
            return _materialPropertyBlock;
        }
    }
    private MaterialPropertyBlock _materialPropertyBlock;

    private List<Renderer> renderers
    {
        get
        {
            if (_renderers.Count <= 0)
                _renderers.AddRange(GetComponentsInChildren<Renderer>());

            return _renderers;
        }
    }
    [SerializeField] private List<Renderer> _renderers = new List<Renderer>();

    public Color redColor
    {
        get { return _redColor; }
        set
        {
            _redColor = value;

            SetColor("_RedColor", _redColor, out _redColor);
        }
    }

    public Color greenColor
    {
        get { return _greenColor; }
        set
        {
            _greenColor = value;

            SetColor("_GreenColor", _greenColor, out _greenColor);
        }
    }

    public Color blueColor
    {
        get { return _blueColor; }
        set
        {
            _blueColor = value;

            SetColor("_BlueColor", _blueColor, out _blueColor);
        }
    }

    [SerializeField]
    private Color _redColor = Color.white, _greenColor = Color.white, _blueColor = Color.white;

    /// <summary>
    /// Called when the script is loaded or a value is changed in the
    /// inspector (Called in the editor only).
    /// </summary>
    void OnValidate()
    {
        SetColors();
    }

    protected void SetColor(string colorName, Color color, out Color referenceColor)
    {
        referenceColor = color;

        if (renderers.Count <= 0)
            return;

        if (renderers[0] != null)
            renderers[0].GetPropertyBlock(materialPropertyBlock);

        foreach (Renderer partRenderer in renderers)
        {
            if (partRenderer == null)
                continue;

            materialPropertyBlock.SetColor(colorName, color);
            partRenderer.SetPropertyBlock(materialPropertyBlock);
        }
    }

    protected void SetColor(string colorName, Color color, Renderer renderer)
    {
        if (renderer != null)
            renderer.GetPropertyBlock(materialPropertyBlock);
        else
        {
            Debug.LogWarning("Renderer is null!");
            return;
        }

        materialPropertyBlock.SetColor(colorName, color);
        renderer.SetPropertyBlock(materialPropertyBlock);
    }

    public void SetColors()
    {
        if (!useColor)
            return;

        redColor = redColor;
        greenColor = greenColor;
        blueColor = blueColor;
    }

    public void SetColors(Renderer renderer)
    {
        SetColor("_RedColor", redColor, renderer);
        SetColor("_GreenColor", greenColor, renderer);
        SetColor("_BlueColor", blueColor, renderer);
    }

    private Material _cachedMaterial;

    public virtual void SetColors(UnityEngine.UI.Graphic graphic)
    {
        // Check if we have a cached material
        if (_cachedMaterial == null)
        {
            // We don't have a cached material, create one
            _cachedMaterial = new Material(graphic.materialForRendering.shader);
        }

        // Set the color properties on the cached material
        _cachedMaterial.SetColor("_RedColor", redColor);
        _cachedMaterial.SetColor("_GreenColor", greenColor);
        _cachedMaterial.SetColor("_BlueColor", blueColor);

        // Set the graphic's material to the cached material
        graphic.material = _cachedMaterial;
    }

    [Button]
    void GetRenderers()
    {
        _renderers.Clear();

        foreach (Renderer partRenderer in GetComponentsInChildren<Renderer>(includeInactive: true))
        {
            _renderers.Add(partRenderer);
        }
    }

    #endregion

    #region Input

    // Movement input
    public virtual void Move(Vector2 direction)
    {
        if (GetAttachedThing() != null)
            GetAttachedThing().Move(direction);
    }

    // Aim input
    public virtual void Aim(Vector2 direction)
    {
        if (GetAttachedThing() != null)
            GetAttachedThing().Aim(direction);
    }

    // Primary input
    public virtual void PrimaryAction(bool pressed)
    {
        if (interaction != null && interaction.canInteract)
        {
            if (pressed)
                interaction.PrimaryAction?.Invoke();
        }
        else if (GetAttachedThing() != null)
            GetAttachedThing().PrimaryAction(pressed);
    }

    // Secondary input
    public virtual void SecondaryAction(bool pressed)
    {
        if (interaction != null && interaction.canInteract)
        {
            if (pressed)
                interaction.SecondaryAction?.Invoke();
        }
        else if (GetAttachedThing() != null)
            GetAttachedThing().SecondaryAction(pressed);
    }

    // Tertiary input
    public virtual void TertiaryAction(bool pressed)
    {
        if (GetAttachedThing() != null)
            GetAttachedThing().TertiaryAction(pressed);
    }

    // Quaternary input
    public virtual void QuaternaryAction(bool pressed)
    {
        if (GetAttachedThing() != null)
            GetAttachedThing().QuaternaryAction(pressed);
    }

    // Left input
    public virtual void LeftAction(bool pressed)
    {
        if (GetAttachedThing() != null)
            GetAttachedThing().LeftAction(pressed);
    }

    // Right input
    public virtual void RightAction(bool pressed)
    {
        if (GetAttachedThing() != null)
            GetAttachedThing().RightAction(pressed);
    }

    public Interaction interaction;

    #endregion
}
