using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class ThingDisplay : MonoBehaviour
{
    private GameThing thingOwner;

    public GameThing thing
    {
        get => _thing;
        set => UpdateDisplay(value);
    }
    private GameThing _thing;

    public void SetThing(GameThing thing, GameThing owner = null)
    {
        UpdateDisplay(thing, owner);

        // Debug.Log(owner.GetType(), this);
    }

    [SerializeField] private Image iconImage;
    public Button iconButton;

    [SerializeField, Space(10)] private List<TextMeshProUGUI> nameTexts;
    [SerializeField] private List<TextMeshProUGUI> descriptionTexts;

    public void Select()
    {
        if (iconButton != null)
            iconButton.Select();
    }

    private void UpdateDisplay(GameThing displayThing = null, GameThing owner = null)
    {
        if (displayThing != null)
            _thing = displayThing;

        if (owner != null)
            thingOwner = owner;

        if (displayThing == null)
        {
            foreach (TextMeshProUGUI text in nameTexts)
                text.text = "";
            foreach (TextMeshProUGUI text in descriptionTexts)
                text.text = "";
            if (iconImage != null)
                iconImage.enabled = false;
            if (iconButton != null)
            {
                iconButton.onClick.RemoveAllListeners();
                iconButton.interactable = false;
            }
        }
        else
        {
            foreach (TextMeshProUGUI text in nameTexts)
                text.text = displayThing.thingName;
            foreach (TextMeshProUGUI text in descriptionTexts)
                text.text = displayThing.thingDescription;

            if (iconImage != null)
            {
                iconImage.enabled = true;
                iconImage.sprite = displayThing.thingIcon;
                displayThing.SetColors(iconImage);
            }
            if (iconButton != null)
            {
                iconButton.onClick.RemoveAllListeners();

                if (thingOwner != null)
                    iconButton.onClick.AddListener(() => displayThing.Use(user: thingOwner));

                iconButton.interactable = true;
            }
        }
    }
}
