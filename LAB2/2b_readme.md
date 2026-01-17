Lab 2B is where students stop “using CloudFront” and start operating CloudFront correctly.

The entire lab is built around one idea AWS emphasizes: cache key (cache policy) and origin forwarding (origin request policy) are different knobs, and getting them wrong causes real incidents (user A sees user B’s data, auth breaks, “random 403s,” etc.). 
https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/understanding-how-origin-request-policies-and-cache-policies-work-together.html?utm_source=chatgpt.com

Below is a full Lab 2B package:
  project intro + workforce relevance
  expected deliverables
  Terraform overlay (Chewbacca style, skeleton where students fill values)
  correctness tests (curl + headers + “cache poisoning” checks)
