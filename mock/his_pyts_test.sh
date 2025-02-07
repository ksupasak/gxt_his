curl -X POST https://localhost:8001/pts/smartems/Generate/gettoken -H "Content-Type: application/json"
curl -X GET "http://localhost:8001/pts/smartems/api/getPatientInfo/?hn=63-01331" -H "Content-Type: application/json"


curl -X GET "http://localhost:3000/his/getPatientInfo/?hn=63-01331" -H "Content-Type: application/json"

TOKEN=123456 CALLER=10.35.222.132 rerun ./start.sh

curl --insecure -X GET "https://localhost:3000/his/getPatientInfo?hn=63-01331&his=SNH" -H "Authorization: Bearer 123456" -H "Content-Type: application/json"