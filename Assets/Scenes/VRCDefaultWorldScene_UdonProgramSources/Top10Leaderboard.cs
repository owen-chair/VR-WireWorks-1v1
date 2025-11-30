
using System.Text;
using UdonSharp;
using UnityEngine;
using VRC.SDK3.StringLoading;
using VRC.SDKBase;
using VRC.Udon.Common.Interfaces;
using VRC.SDK3.Data;

public class Top10Leaderboard : UdonSharpBehaviour
{
    /*
    [Header("Server Configuration")]
    [SerializeField]
    private string serverUrl = "http://your-server.com:8080";
    
    [Header("UI Elements")]
    public TMPro.TMP_Text m_PlayerNameText;
    public TMPro.TMP_Text m_WinsText;
    public TMPro.TMP_Text m_LossesText;
    
    [Header("Refresh Settings")]
    public float refreshInterval = 30f; // Refresh every 30 seconds
    
    private string m_PlayerNameTextString = "";
    private string m_WinsTextString = "";
    private string m_LossesTextString = "";
    
    private const string CLIENT_KEY = "VRC_DOTBOXES_SECRET_KEY_2025";
    
    void Start()
    {
        LoadTop10Data();
        
        // Set up periodic refresh
        if (refreshInterval > 0)
        {
            SendCustomEventDelayedSeconds(nameof(ScheduledRefresh), refreshInterval);
        }
    }
    
    public void LoadTop10Data()
    {
        // Create the request JSON
        DataDictionary requestData = new DataDictionary();
        requestData["clientkey"] = CLIENT_KEY;
        
        // Convert to JSON string using VRC SDK method
        DataToken requestToken = new DataToken(requestData);
        if (VRCJson.TrySerializeToJson(requestToken, JsonExportType.Minify, out DataToken jsonToken))
        {
            string jsonString = jsonToken.String;
            
            // Encode to base64
            byte[] jsonBytes = Encoding.UTF8.GetBytes(jsonString);
            string base64Request = System.Convert.ToBase64String(jsonBytes);
            
            // Create the full URL dynamically
            string fullUrl = $"{serverUrl}/data/top10/{base64Request}";
            
            Debug.Log($"Loading top 10 data from: {fullUrl}");
            
            // Create VRCUrl at runtime (may require "Allow Untrusted URLs" setting)
            VRCUrl dynamicUrl = VRCUrl(fullUrl);
            VRCStringDownloader.LoadUrl(dynamicUrl, (IUdonEventReceiver)this);
        }
        else
        {
            Debug.LogError("Failed to serialize request data to JSON");
        }
    }
    
    public override void OnStringLoadSuccess(IVRCStringDownload result)
    {
        Debug.Log("Top 10 data loaded successfully");
        string jsonResponse = result.Result;
        
        try
        {
            // Parse the JSON response
            if (VRCJson.TryDeserializeFromJson(jsonResponse, out DataToken responseToken))
            {
                if (responseToken.DataDictionary.TryGetValue("players", out DataToken playersToken))
                {
                    DataList playersList = playersToken.DataList;
                    DisplayTop10Data(playersList);
                }
                else
                {
                    Debug.LogError("No 'players' field found in response");
                }
            }
            else
            {
                Debug.LogError("Failed to parse JSON response");
            }
        }
        catch (System.Exception e)
        {
            Debug.LogError($"Error parsing top 10 data: {e.Message}");
        }
    }
    
    public override void OnStringLoadError(IVRCStringDownload result)
    {
        Debug.LogError($"Error loading top 10 data: {result.ErrorCode} - {result.Error}");
    }
    
    private void DisplayTop10Data(DataList playersList)
    {
        // Clear existing strings
        m_PlayerNameTextString = "";
        m_WinsTextString = "";
        m_LossesTextString = "";
        
        // Process each player in the top 10
        for (int i = 0; i < playersList.Count && i < 10; i++)
        {
            DataDictionary player = playersList[i].DataDictionary;
            
            // Extract player data (only public fields)
            string playerName = "Unknown";
            int wins = 0;
            int losses = 0;
            
            if (player.TryGetValue("playername", out DataToken nameToken))
                playerName = nameToken.String;
                
            if (player.TryGetValue("wins", out DataToken winsToken))
                wins = (int)winsToken.Number;
                
            if (player.TryGetValue("losses", out DataToken lossesToken))
                losses = (int)lossesToken.Number;
            
            // Add rank number and build display strings
            int rank = i + 1;
            m_PlayerNameTextString += $"{rank}. {playerName}\n";
            m_WinsTextString += $"{wins}\n";
            m_LossesTextString += $"{losses}\n";
        }
        
        // Update UI elements
        UpdateUI();
    }
    
    private void UpdateUI()
    {
        if (m_PlayerNameText != null)
            m_PlayerNameText.text = m_PlayerNameTextString;
            
        if (m_WinsText != null)
            m_WinsText.text = m_WinsTextString;
            
        if (m_LossesText != null)
            m_LossesText.text = m_LossesTextString;
    }
    
    // Scheduled refresh method for automatic updates
    public void ScheduledRefresh()
    {
        LoadTop10Data();
        
        // Schedule the next refresh
        if (refreshInterval > 0)
        {
            SendCustomEventDelayedSeconds(nameof(ScheduledRefresh), refreshInterval);
        }
    }
    
    // Public method to manually refresh the leaderboard
    public void RefreshLeaderboard()
    {
        LoadTop10Data();
    }
    */
}
