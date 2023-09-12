using UnityEngine;
using UnityEngine.UI;

public class EnergyBar : MonoBehaviour
{
    [SerializeField] private Gradient energyGradient;

    private Slider energyBar
    {
        get
        {
            if (_energyBar == null)
                TryGetComponent(out _energyBar);

            return _energyBar;
        }
    }
    private Slider _energyBar;

    private Image fillImage
    {
        get
        {
            if (_fillImage == null)
                energyBar.fillRect.TryGetComponent(out _fillImage);

            return _fillImage;
        }
    }
    private Image _fillImage;

    // Start is called before the first frame update
    void Start()
    {
        CharacterThing character = GetComponentInParent<CharacterThing>();

        if (character != null)
        {
            SetupEnergyBar(character);
            character.onEnergyChanged += UpdateEnergyBar;
        }
    }

    private void SetupEnergyBar(CharacterThing character)
    {
        energyBar.maxValue = character.maxEnergy;
        UpdateEnergyBar(character.energy);
    }

    private void UpdateEnergyBar(float energyLevel)
    {
        energyBar.value = energyLevel;
        fillImage.color = energyGradient.Evaluate(energyBar.normalizedValue);
    }
}
