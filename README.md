# lambda_ruby_ffmpeg

## deploy

```
docker build . -t lambda_ruby_ffmpeg
docker run -v "{PWD}":/var/task/output  lambda_ruby_ffmpeg
```

and attach the permission properly
```
  attach-role-policy \
--role-name <value> \
--policy-arn <value> 
```
example :
```
aws iam attach-role-policy \
--policy-arn arn:aws:iam::aws:policy/ReadWriteAccess \
--role-name ReadWriteRole
```

## usage
post
```
{
  "s3_resource": <region>,
  "bucket_name": <bucket>,
  "object_key": <key>
}
```

and you can find

> s3://<bucket>:<key>/00000.ts
> s3://<bucket>:<key>/00001.ts
> s3://<bucket>:<key>/00002.ts
> s3://<bucket>:<key>/00003.ts
> ...
> playlist.m3u8

