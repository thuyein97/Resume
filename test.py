import unittest
from lambda_function.lambda_function import lambda_handler

class TestLambdaFunction(unittest.TestCase):
    
    def test_lambda_handler(self):
        # Test with an event that includes a 'name' key
        event = {'body': 23}
        context = {}
        
        response = lambda_handler(event, context)
        self.assertEqual(response['statusCode'], 200)
        self.assertIsInstance(response['body'], str)


if __name__ == '__main__':
    unittest.main()
    print("Everything passed")
