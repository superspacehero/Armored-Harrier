using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[AddComponentMenu("Game Things/Interactions"), DisallowMultipleComponent]
public class Interactions : MonoBehaviour
{
    private GameThing thisThing
    {
        get
        {
            if (_thisThing == null)
            {
                Transform parent = transform.parent;

                // Loop up the hierarchy, looking for GameThings that aren't CharacterPartThings
                while (parent.parent != null && _thisThing == null)
                {
                    parent.TryGetComponent(out _thisThing);
                    if (_thisThing is CharacterPartThing)
                        _thisThing = null;

                    parent = parent.parent;
                }
            }

            if (collisionInteraction != null)
                collisionInteraction.thisThing = _thisThing;

            return _thisThing;
        }
    }
    private GameThing _thisThing;

    public GameThing otherThing;

    /// <summary>
    /// OnTriggerEnter is called when the Collider other enters the trigger.
    /// </summary>
    /// <param name="other">The other Collider involved in this collision.</param>
    public void OnTriggerEnter(Collider other)
    {
        if (other.TryGetComponent(out otherThing) && collisionInteraction?.canInteract == true)
        {
            collisionInteraction?.Interact(otherThing, thisThing);
        }
    }

    /// <summary>
    /// OnTriggerExit is called when the Collider other has stopped touching the trigger.
    /// </summary>
    /// <param name="other">The other Collider involved in this collision.</param>
    public void OnTriggerExit(Collider other)
    {
        if (other.TryGetComponent(out otherThing) && collisionInteraction?.canInteract == true)
        {
            collisionInteraction?.StopInteract(otherThing, thisThing);
        }
    }

    /// <summary>
    /// OnCollisionEnter is called when this collider/rigidbody has begun
    /// touching another rigidbody/collider.
    /// </summary>
    /// <param name="other">The Collision data associated with this collision.</param>
    public void OnCollisionEnter(Collision other)
    {
        if (other.collider.TryGetComponent(out otherThing) && collisionInteraction?.canInteract == true)
        {
            collisionInteraction?.Interact(otherThing, thisThing);
        }
    }

    /// <summary>
    /// OnCollisionExit is called when this collider/rigidbody has
    /// stopped touching another rigidbody/collider.
    /// </summary>
    /// <param name="other">The Collision data associated with this collision.</param>
    public void OnCollisionExit(Collision other)
    {
        if (other.collider.TryGetComponent(out otherThing) && collisionInteraction?.canInteract == true)
        {
            collisionInteraction?.StopInteract(otherThing, thisThing);
        }
    }

    [SerializeReference]
    public Interaction collisionInteraction;
}

public abstract class Interaction
{
    public GameThing thisThing { get; set; }
    public virtual bool canInteract { get => true; }
    public virtual bool interacting { get; set; }
    public virtual void Interact(GameThing interactor, GameThing interactee)
    {
        if (interactor != null)
            interactor.interaction = this;
        thisThing = interactee;
    }
    public virtual void StopInteract(GameThing interactor, GameThing interactee)
    {
        if (interactor != null)
            interactor.interaction = null;
    }

    public virtual UnityEngine.Events.UnityAction PrimaryAction => null;
    public virtual UnityEngine.Events.UnityAction SecondaryAction => null;
}

public class PickUpInteraction : Interaction
{
    public override void Interact(GameThing interactor, GameThing interactee)
    {
        base.Interact(interactor, interactee);

        if (interactor.inventory)
        {
            interactor.inventory.AddThing(interactee);
        }
    }
}

public class OpenMenuInteraction : Interaction
{
    public Menu menu;

    public override UnityEngine.Events.UnityAction PrimaryAction
    {
        get
        {
            return () =>
            {
                menu?.Select();
                interacting = true;
            };
        }
    }

    public override UnityEngine.Events.UnityAction SecondaryAction
    {
        get
        {
            return () =>
            {
                menu?.Deselect();
                interacting = false;
            };
        }
    }
}