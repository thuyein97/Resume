// Get the visitor count element
const visitorCountElement = document.getElementById('count');

// Function to fetch visitor count from the API
async function fetchVisitorCount() {
  try {
    const response = await fetch('https://e3x7hvpdff.execute-api.us-east-1.amazonaws.com/New/visitors'); // Replace with your API endpoint
    const data = await response.json();
    visitorCountElement.textContent = data.body;
  } catch (error) {
    console.error('Error fetching visitor count:', error);
    // Handle errors, e.g., display an error message or fallback to local storage
  }
}

// Initial fetch on page load
fetchVisitorCount();

