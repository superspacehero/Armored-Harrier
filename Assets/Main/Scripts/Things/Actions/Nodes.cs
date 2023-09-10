using System.Collections.Generic;
using UnityEngine;
using Pathfinding;

public class Nodes : MonoBehaviour
{
    // The static instance of the class
    public static Nodes instance;

    // The grid graph to use for pathfinding
    public PointGraph pointGraph
    {
        get
        {
            if (_pointGraph == null)
                _pointGraph = AstarPath.active.data.pointGraph;

            return _pointGraph;
        }
    }
    private PointGraph _pointGraph;

    // The prefab to use for the node display
    public GameObject nodePrefab;

    // The parent transform to use for the node display objects
    public Transform nodeParent;

    // A dictionary to store the node display objects, with the GraphNode as the key
    Dictionary<GraphNode, GameObject> nodeObjects = new Dictionary<GraphNode, GameObject>();

    // A queue to store the inactive node display objects
    Queue<GameObject> inactiveObjects = new Queue<GameObject>();

    [SerializeField, NaughtyAttributes.Foldout("Colors")]
    public Color walkableColor = Color.white, currentColor = Color.blue, occupiedColor = Color.red;

    private void Awake()
    {
        // Set the static instance
        instance = this;
    }

    // A function to display the nodes
    public void DisplayNodes(List<GraphNode> nodes)
    {
        HideNodes();

        // Iterate through the nodes
        foreach (GraphNode node in nodes)
        {
            // Get a node display object from the queue or create a new one
            GameObject nodeObject;
            if (inactiveObjects.Count > 0)
            {
                nodeObject = inactiveObjects.Dequeue();
            }
            else
            {
                nodeObject = Instantiate(nodePrefab, nodeParent);
            }

            // Add the node display object to the dictionary
            if (node != null && nodeObject != null)
                nodeObjects.Add(node, nodeObject);
            else
                continue;

            // Set the position of the node display object to the position of the GraphNode
            nodeObject.transform.position = (Vector3)node.position;

            // Activate the node display object
            nodeObject.SetActive(true);
        }
    }

    public void DisplayNodes(Vector3 position, float radius, Vector2 maxHeightLimits)
    {
        // Get the nodes within the radius
        DisplayNodes(GetNodesInRadius(position, radius, maxHeightLimits));
    }

    private static Vector3Int[] directions = new Vector3Int[]
    {
        Vector3Int.forward,
        Vector3Int.back,
        Vector3Int.left,
        Vector3Int.right
    };

    public static List<GraphNode> GetNodesInRadius(Vector3 position, float radius, Vector2 maxHeightLimits)
    {
        List<GraphNode> nodes = new List<GraphNode>();

        if (maxHeightLimits.x < 0)
            maxHeightLimits.x = float.PositiveInfinity;
        if (maxHeightLimits.y < 0)
            maxHeightLimits.y = float.PositiveInfinity;

        // Debug.Log($"Upward height limit: {maxHeightLimits.x}, downward height limit: {maxHeightLimits.y}");

        // If radius is set to infinity, add all walkable nodes in the gridGraph to the nodes list.
        if (float.IsInfinity(radius))
        {
            foreach (var node in instance.pointGraph.nodes)
            {
                if (node.Walkable && !CheckNodeOccupied(node) &&
                    node.position.y <= maxHeightLimits.y &&
                    node.position.y >= position.y - maxHeightLimits.x)
                {
                    nodes.Add(node);
                }
            }
        }
        else
        {
            GraphNode currentNode = instance.pointGraph.GetNearest(position).node;
            nodes.Add(currentNode);

            Queue<GraphNode> queue = new Queue<GraphNode>();
            queue.Enqueue(currentNode);

            // Iterate through all the nodes in the movement range
            for (int i = 0; i < radius; i++)
            {
                int queueCount = queue.Count;
                for (int j = 0; j < queueCount; j++)
                {
                    GraphNode searchNode = queue.Dequeue();
                    // Iterate through all the directions
                    foreach (Vector3 direction in directions)
                    {
                        // Get the node in the direction
                        GraphNode node = null;
                        if (searchNode != null)
                            node = instance.pointGraph.GetNearest((Vector3)searchNode.position + direction).node;

                        if (node != null && !nodes.Contains(node) && node.Walkable)
                        {
                            // If the node is not in the valid spaces list and is walkable and within the maxHeightLimits, add it to the list
                            float deltaY = ((Vector3)node.position).y - ((Vector3)searchNode.position).y;

                            if ((deltaY <= maxHeightLimits.x) && // Upward movement within limit
                                (deltaY <= maxHeightLimits.y))   // Downward movement within limit
                            {
                                nodes.Add(node);
                                queue.Enqueue(node);
                            }
                        }
                    }
                }
            }

        }

        return nodes;
    }

    // A function to hide the nodes
    public void HideNodes()
    {
        // Iterate through the node display objects
        foreach (GameObject nodeObject in nodeObjects.Values)
        {
            // Deactivate the node display object and add it to the queue
            nodeObject.SetActive(false);
            inactiveObjects.Enqueue(nodeObject);
        }

        // Clear the dictionary
        nodeObjects.Clear();
    }

    public GameObject GetNodeObject(GraphNode node)
    {
        // Return the node display object for the GraphNode
        return (nodeObjects.ContainsKey(node)) ? nodeObjects[node] : null;
    }

    public void ColorNodeObject(GraphNode node)
    {
        // Get the node display object for the GraphNode,
        if (GetNodeObject(node) != null && GetNodeObject(node).transform.GetChild(0).TryGetComponent(out SpriteRenderer renderer))
        {
            // and set the color of the node display object
            if (CheckNodeOccupied(node))
                ColorNodeObject(node, occupiedColor);
            else
                ColorNodeObject(node, walkableColor);
        }
    }

    public void ColorNodeObject(GraphNode node, Color color)
    {
        // Get the node display object for the GraphNode,
        if (GetNodeObject(node) != null && GetNodeObject(node).transform.GetChild(0).TryGetComponent(out SpriteRenderer renderer))
        {
            // and set the color of the node display object
            renderer.color = color;
        }
    }

    public void ColorNodeObjects(List<GraphNode> nodes)
    {
        // Iterate through the GraphNodes
        foreach (GraphNode node in nodes)
        {
            // Color the node display object for the GraphNode
            ColorNodeObject(node);
        }
    }

    public static void SetNodeTag(GraphNode node, uint tag, GameThing thing, bool log = false)
    {
        if (node != null)
        {
            if (log)
            {
                uint previousTag = node.Tag;

                Debug.Log($"{thing.thingName}'s previous: {previousTag}. Current: {tag}.", thing);
            }

            node.Tag = tag;
        }
    }

    public static void OccupyNode(GraphNode node, GameThing thing, bool log = false)
    {
        if (node != null)
        {
            SetNodeTag(node, 1, thing, log);
        }
    }

    public static void OccupyNode(Vector3 position, GameThing thing, bool log = false)
    {
        if (AstarPath.active != null)
        {
            GraphNode node = instance.pointGraph.GetNearest(position).node;

            if (node != null)
                OccupyNode(node, thing, log);
        }
    }

    public static void UnoccupyNode(GraphNode node, GameThing thing, bool log = false)
    {
        if (node != null)
        {
            SetNodeTag(node, 0, thing, log);
        }
    }

    public static void UnoccupyNode(Vector3 position, GameThing thing, bool log = false)
    {
        if (AstarPath.active != null)
        {
            GraphNode node = instance.pointGraph.GetNearest(position).node;

            if (node != null)
                UnoccupyNode(node, thing, log);
        }
    }

    public static bool CheckNodeOccupied(GraphNode node)
    {
        return node.Tag == 1;
    }

    public static List<GraphNode> GetPathToNode(Vector3 startPosition, Vector3 endPosition, int maxDistance = 0, int disabledTag = 1)
    {
        // Get the path from the start node to the end node
        ABPath path = ABPath.Construct(startPosition, endPosition);

        // Disable the tag to prevent the ABPath from using nodes with that tag
        path.enabledTags = ~(1 << disabledTag);

        // Calculate the path
        AstarPath.StartPath(path);

        // Wait for the path to be calculated
        while (!path.IsDone())
        {
            // Do nothing
        }

        // If a max distance is provided, check if the path is within the max distance
        // If not, trim the path to the max distance
        if (maxDistance > 0 && path.GetTotalLength() > maxDistance)
        {
            path.path.RemoveRange(maxDistance, path.path.Count - maxDistance);
        }

        // Return the path
        return path.path;
    }

    public static int GetNodeDistance(Vector3 startPosition, Vector3 endPosition)
    {
        // Get the path from the start node to the end node
        ABPath path = ABPath.Construct(startPosition, endPosition);

        // Calculate the path
        AstarPath.StartPath(path);

        // Wait for the path to be calculated
        while (!path.IsDone())
        {
            // Do nothing
        }

        // Return the path
        return (int)path.GetTotalLength();
    }
}