import express from 'express';
import morgan from 'morgan';
import bodyParser from 'body-parser';

const port = 5999
const app = express();

app.set('trust proxy', 'uniquelocal');

app.use(morgan('common', { immediate: true }));
app.use(bodyParser.json());

app.post('/v2/:module/:method', async (req, res) => {
    const { module: reqModule, method: reqMethod } = req.params;
    const token = req.headers['authorization']?.startsWith('Token') ? 
        req.headers['authorization'].split(' ')[1] : 
        undefined;

    const prepareBody = (data: any) => {
        console.log('handling body', data);
        const body = {
            id: 1,
            jsonrpc: '2.0',
            method: reqMethod,
            params: null,
        };

        if (data['jsonrpc']) {
            body.id = data['id'];
            body.params = data['params'];
        } else if (Array.isArray(data) || (typeof data === 'object' && data !== null)) {
            body.params = data;
        }

        if (!(reqModule === 'empire' && reqMethod === 'login') && !!token && body.params !== null) {
            body.params = Array.isArray(body.params) ?
                [token, ...body.params] :
                { session_id: token, ...body.params};
        }

        return body;
    }

    const body = prepareBody(req.body);
    console.log(`hitting /${reqModule} with:`, body);
    const response = await fetch(`http://lacuna-server:5000/${reqModule}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
    });
    const result = await response.json();
    console.log('status', response.status);
    console.log('result', result);

    res.status(response.status).json(result);
});

app.listen(port, () => {
    console.log(`TLE Community v2 API app listening on port ${port}`)
});
