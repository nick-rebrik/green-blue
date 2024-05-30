from django.http import HttpResponse


def index(request):
    return HttpResponse('Blue work!')
    # return HttpResponse('Green work!')
