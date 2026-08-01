This is a perfect application for GitOps training.

The image never changes. Only the Kubernetes manifests change. Students will clearly see that Git is the source of truth.

## Project Structure

```text
gitops-nginx/
├── Dockerfile
├── index.template.html
└── entrypoint.sh
```

---

# Dockerfile

```dockerfile
FROM nginx:alpine

# Copy template
COPY index.template.html /usr/share/nginx/html/index.template.html

# Copy startup script
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]
```

---

# entrypoint.sh

```sh
#!/bin/sh

# Default values

export COMPANY=${COMPANY:-Vishwacloudlab}
export APPLICATION=${APPLICATION:-GitOps Demo}
export ENVIRONMENT=${ENVIRONMENT:-Dev}
export VERSION=${VERSION:-v1.0.0}
export COLOR_THEME=${COLOR_THEME:-Blue}
export BUILD_DATE=${BUILD_DATE:-30-Jul-2026}

envsubst \
'$COMPANY $APPLICATION $ENVIRONMENT $VERSION $COLOR_THEME $BUILD_DATE' \
< /usr/share/nginx/html/index.template.html \
> /usr/share/nginx/html/index.html

exec "$@"
```

---

# index.template.html

```html
<!DOCTYPE html>
<html>

<head>
    <title>GitOps Demo</title>

    <style>

        body{
            font-family: Arial;
            background:#f5f5f5;
        }

        .card{
            width:650px;
            margin:60px auto;
            padding:30px;
            border-radius:10px;
            background:white;
            box-shadow:0 0 10px rgba(0,0,0,.2);
        }

        h1{
            text-align:center;
            color:#1976d2;
        }

        table{
            width:100%;
            border-collapse:collapse;
            margin-top:25px;
        }

        td{
            padding:10px;
            border-bottom:1px solid #ddd;
            font-size:20px;
        }

        td:first-child{
            font-weight:bold;
            width:220px;
        }

    </style>

</head>

<body>

<div class="card">

<h1>GitOps Demo Application</h1>

<table>

<tr>
<td>Company</td>
<td>${COMPANY}</td>
</tr>

<tr>
<td>Application</td>
<td>${APPLICATION}</td>
</tr>

<tr>
<td>Environment</td>
<td>${ENVIRONMENT}</td>
</tr>

<tr>
<td>Version</td>
<td>${VERSION}</td>
</tr>

<tr>
<td>Color Theme</td>
<td>${COLOR_THEME}</td>
</tr>

<tr>
<td>Build Date</td>
<td>${BUILD_DATE}</td>
</tr>

</table>

</div>

</body>

</html>
```

---

# Build Image

```bash
docker build -t vishwacloudlab/gitops-nginx:v1 .
```

---

# Push Image

```bash
docker login

docker push vishwacloudlab/gitops-nginx:v1
```

---

## Test Locally

```bash
docker run -d \
-p 8080:80 \
-e COMPANY="Vishwacloudlab" \
-e APPLICATION="GitOps Demo" \
-e ENVIRONMENT="Development" \
-e VERSION="v1.0.0" \
-e COLOR_THEME="Blue" \
-e BUILD_DATE="30-Jul-2026" \
vishwacloudlab/gitops-nginx:v1
```

Open

```
http://localhost:8080
```

---

## Kubernetes Deployment Example

Students only edit these values:

```yaml
env:
  - name: COMPANY
    value: Vishwacloudlab

  - name: APPLICATION
    value: GitOps Demo

  - name: ENVIRONMENT
    value: Development

  - name: VERSION
    value: v1.0.0

  - name: COLOR_THEME
    value: Blue

  - name: BUILD_DATE
    value: 30-Jul-2026
```

Then commit:

```bash
git add .
git commit -m "Update application version to v1.1.0"
git push
```

ArgoCD syncs automatically, the pod restarts, and the webpage updates—demonstrating GitOps without rebuilding the container image.

---

## Recommended Docker Hub Image Name

For consistency across all your GitOps labs, use a stable image name such as:

```text
vishwacloudlab/gitops-nginx
```

Tag the first version as:

```text
vishwacloudlab/gitops-nginx:v1
```

You can reuse this same image throughout your entire GitOps training series (Helm, Kustomize, Secrets, Drift Detection, Progressive Delivery). Only the Kubernetes manifests will change, making it an ideal teaching example.
